# Coding Patterns

This section contains practical coding examples and best practices from the Villager Rails project.

## Table of Contents

- [Service Objects](#service-objects)
- [Background Jobs](#background-jobs)
- [Turbo Stream Patterns](#turbo-stream-patterns)
- [Testing Patterns](#testing-patterns)
- [Model Patterns](#model-patterns)
- [Controller Patterns](#controller-patterns)

## Service Objects

### Basic Service Structure

```ruby
# app/services/produce_resources_from_building_service.rb
class ProduceResourcesFromBuildingService
  include Turbo::Streams::ActionHelper

  def initialize(village_building)
    @village_building = village_building
    @village = village_building.village
  end

  def call
    return false unless can_produce?
    
    ActiveRecord::Base.transaction do
      produce_resources
      update_production_timestamp
    end
    
    broadcast_resource_updates
    true
  end

  private

  def can_produce?
    has_outputs? && production_time_elapsed?
  end

  def has_outputs?
    @village_building.building.building_outputs.exists?
  end

  def production_time_elapsed?
    return true if @village_building.last_production_at.nil?
    
    Time.current - @village_building.last_production_at >= production_interval
  end

  def production_interval
    30.seconds # Configurable production cycle
  end

  def produce_resources
    @village_building.building.building_outputs.includes(:resource).each do |output|
      village_resource = find_or_create_village_resource(output.resource)
      village_resource.increment!(:amount, output.amount)
    end
  end

  def find_or_create_village_resource(resource)
    @village.village_resources.find_or_create_by(resource: resource) do |vr|
      vr.amount = 0
    end
  end

  def update_production_timestamp
    @village_building.update_column(:last_production_at, Time.current)
  end

  def broadcast_resource_updates
    broadcast_replace_to(
      [@village, :resources],
      target: 'resources-list',
      partial: 'villages/resources_list',
      locals: { village: @village }
    )
  end
end
```

### Service Object Benefits

1. **Single Responsibility**: Each service handles one business operation
2. **Transaction Safety**: Database operations are wrapped in transactions
3. **Error Handling**: Clear success/failure return values
4. **Broadcasting**: Automatic UI updates via Turbo Streams
5. **Testability**: Easy to unit test in isolation

## Background Jobs

### Job Structure with Error Handling

```ruby
# app/jobs/village_loop_job.rb
class VillageLoopJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(village_id)
    village = Village.find(village_id)
    return unless village.active?

    VillageLoopService.new(village).call
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "Village #{village_id} not found: #{e.message}"
    # Don't retry for missing records
    raise e if attempts < 3
  rescue StandardError => e
    Rails.logger.error "Village loop failed for #{village_id}: #{e.message}"
    raise e # Will trigger retry
  end
end

# Recurring job for all villages
class PlayLoopJob < ApplicationJob
  queue_as :default

  def perform
    Village.active.find_each do |village|
      VillageLoopJob.perform_later(village.id)
    end
  end
end
```

### Job Testing Pattern

```ruby
# spec/jobs/village_loop_job_spec.rb
RSpec.describe VillageLoopJob, type: :job do
  let(:village) { create(:village, :with_buildings) }

  describe '#perform' do
    it 'calls VillageLoopService with correct village' do
      service_double = instance_double(VillageLoopService)
      expect(VillageLoopService).to receive(:new).with(village).and_return(service_double)
      expect(service_double).to receive(:call)

      described_class.new.perform(village.id)
    end

    context 'when village is inactive' do
      let(:village) { create(:village, active: false) }

      it 'does not call the service' do
        expect(VillageLoopService).not_to receive(:new)
        described_class.new.perform(village.id)
      end
    end
  end
end
```

## Turbo Stream Patterns

### Real-Time Resource Updates

```ruby
# In services that modify resources
def broadcast_resource_updates
  broadcast_replace_to(
    [@village, :resources],
    target: 'resources-list',
    partial: 'villages/resources_list',
    locals: { village: @village.reload }
  )
end

# In controllers for immediate feedback
def create
  @village_building = @village.village_buildings.build(village_building_params)
  
  if @village_building.save
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @village }
    end
  else
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace('building-form', partial: 'form', locals: { village_building: @village_building }) }
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

### Turbo Stream View Templates

```erb
<%# app/views/village_buildings/create.turbo_stream.erb %>
<%= turbo_stream.append 'village-buildings' do %>
  <%= render 'village_building', village_building: @village_building %>
<% end %>

<%= turbo_stream.replace 'building-form' do %>
  <%= render 'form', village_building: @village.village_buildings.build %>
<% end %>

<%= turbo_stream.replace 'resources-list' do %>
  <%= render 'villages/resources_list', village: @village %>
<% end %>
```

## Testing Patterns

### System Test for Real-Time Features

```ruby
# spec/system/village_auto_refresh_spec.rb
RSpec.describe 'Village auto-refresh', type: :system, js: true do
  let(:user) { create(:user) }
  let(:village) { create(:village, :with_resources, user: user) }

  before do
    sign_in user
    visit village_path(village)
  end

  it 'updates resources automatically via background jobs' do
    # Initial resource state
    initial_wood = village.resource_amount('Wood')
    
    # Wait for the auto-refresh to occur
    expect(page).to have_css('#resources-list', wait: 35)
    
    # Trigger background job manually to simulate auto-refresh
    VillageLoopJob.perform_now(village.id)
    
    # Wait for Turbo Stream update
    expect(page).to have_css('#resources-list', wait: 10)
    
    # Verify resource increase (assuming wood-producing building exists)
    within('#resources-list') do
      expect(page).to have_content('Wood')
    end
  end

  it 'maintains connection during background updates' do
    # Verify page doesn't reload during updates
    page_load_time = page.evaluate_script('performance.timing.loadEventEnd')
    
    # Wait for multiple refresh cycles
    sleep 65 # Two 30-second cycles
    
    current_page_load_time = page.evaluate_script('performance.timing.loadEventEnd')
    expect(current_page_load_time).to eq(page_load_time)
  end
end
```

### Service Object Testing

```ruby
# spec/services/produce_resources_from_building_service_spec.rb
RSpec.describe ProduceResourcesFromBuildingService do
  let(:village) { create(:village) }
  let(:building) { create(:building, :with_wood_output) }
  let(:village_building) { create(:village_building, village: village, building: building) }
  let(:service) { described_class.new(village_building) }

  describe '#call' do
    context 'when production time has elapsed' do
      before do
        village_building.update!(last_production_at: 1.minute.ago)
      end

      it 'produces resources' do
        expect { service.call }.to change { village.resource_amount('Wood') }.by(10)
      end

      it 'updates last production timestamp' do
        service.call
        expect(village_building.reload.last_production_at).to be_within(1.second).of(Time.current)
      end

      it 'broadcasts resource updates' do
        expect(service).to receive(:broadcast_replace_to)
        service.call
      end
    end

    context 'when production time has not elapsed' do
      before do
        village_building.update!(last_production_at: 10.seconds.ago)
      end

      it 'does not produce resources' do
        expect { service.call }.not_to change { village.resource_amount('Wood') }
      end
    end
  end
end
```

## Model Patterns

### Resource Management

```ruby
# app/models/village.rb
class Village < ApplicationRecord
  belongs_to :user
  has_many :village_buildings, dependent: :destroy
  has_many :village_resources, dependent: :destroy
  has_many :buildings, through: :village_buildings
  has_many :resources, through: :village_resources

  scope :active, -> { where(active: true) }

  def resource_amount(resource_name)
    village_resources.joins(:resource)
                    .where(resources: { name: resource_name })
                    .sum(:amount)
  end

  def can_afford?(costs)
    costs.all? { |cost| resource_amount(cost.resource.name) >= cost.amount }
  end

  def deduct_costs(costs)
    return false unless can_afford?(costs)

    ActiveRecord::Base.transaction do
      costs.each do |cost|
        village_resource = village_resources.joins(:resource)
                                          .find_by(resources: { name: cost.resource.name })
        village_resource.decrement!(:amount, cost.amount)
      end
    end
    true
  end

  def add_resource(resource_name, amount)
    resource = Resource.find_by(name: resource_name)
    return false unless resource

    village_resource = village_resources.find_or_create_by(resource: resource) do |vr|
      vr.amount = 0
    end
    village_resource.increment!(:amount, amount)
  end
end
```

### Building Production Logic

```ruby
# app/models/building.rb
class Building < ApplicationRecord
  has_many :building_outputs, dependent: :destroy
  has_many :output_resources, through: :building_outputs, source: :resource
  has_many :costs, dependent: :destroy
  has_many :cost_resources, through: :costs, source: :resource

  scope :available, -> { where(available: true) }

  def production_per_cycle
    building_outputs.sum(:amount)
  end

  def total_cost
    costs.sum(:amount)
  end

  def can_be_built_by?(village)
    village.can_afford?(costs)
  end
end
```

## Controller Patterns

### Resource-Based Controllers

```ruby
# app/controllers/village_buildings_controller.rb
class VillageBuildingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_village
  before_action :set_village_building, only: [:show, :destroy]

  def new
    @village_building = @village.village_buildings.build
    @buildings = Building.available.includes(:building_outputs, :costs)
  end

  def create
    @village_building = @village.village_buildings.build(village_building_params)
    
    if validate_construction && @village_building.save
      handle_successful_construction
    else
      handle_failed_construction
    end
  end

  def destroy
    @village_building.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @village }
    end
  end

  private

  def set_village
    @village = current_user.villages.find(params[:village_id])
  end

  def set_village_building
    @village_building = @village.village_buildings.find(params[:id])
  end

  def village_building_params
    params.require(:village_building).permit(:building_id, :tile_id)
  end

  def validate_construction
    building = Building.find(village_building_params[:building_id])
    unless building.can_be_built_by?(@village)
      @village_building.errors.add(:base, 'Insufficient resources')
      return false
    end
    
    @village.deduct_costs(building.costs)
  end

  def handle_successful_construction
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @village, notice: 'Building constructed successfully!' }
    end
  end

  def handle_failed_construction
    @buildings = Building.available.includes(:building_outputs, :costs)
    respond_to do |format|
      format.turbo_stream { render :new }
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

## Performance Patterns

### Efficient Queries

```ruby
# Avoid N+1 queries with includes
villages = Village.includes(:village_buildings, :village_resources, :user)

# Use joins for filtering
productive_villages = Village.joins(:village_buildings)
                            .where(village_buildings: { building_id: productive_building_ids })

# Batch loading for background jobs
Village.active.find_in_batches(batch_size: 100) do |village_batch|
  village_batch.each { |village| VillageLoopJob.perform_later(village.id) }
end
```

### Caching Strategies

```ruby
# Fragment caching for expensive partials
<%= cache [@village, @village.village_resources.maximum(:updated_at)] do %>
  <%= render 'resources_list', village: @village %>
<% end %>

# Counter caching for frequently accessed counts
class Village < ApplicationRecord
  has_many :village_buildings, counter_cache: true
end

# Memoization for expensive calculations
def total_production_per_hour
  @total_production_per_hour ||= village_buildings.joins(:building)
                                                .sum('buildings.production_rate * 120') # 30-second cycles
end
```

## Related Documentation

- [Design Patterns](../design-patterns/README.md)
- [Architecture Overview](../architecture/README.md)
- [Testing Guide](../learning-resources/testing-guide.md)
