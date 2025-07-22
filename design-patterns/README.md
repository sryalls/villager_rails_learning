# Design Patterns

This section documents the design patterns and architectural decisions used in the Villager Rails project.

## Service Objects Pattern

### Overview
Service objects encapsulate complex business logic, keeping controllers thin and models focused on data persistence.

### Implementation
```ruby
# app/services/produce_resources_from_building_service.rb
class ProduceResourcesFromBuildingService
  def initialize(village_building)
    @village_building = village_building
    @village = village_building.village
  end

  def call
    return unless can_produce?
    
    produce_resources
    update_last_production_time
    broadcast_updates
  end

  private

  def can_produce?
    @village_building.building.building_outputs.any? &&
      time_since_last_production >= production_interval
  end

  def produce_resources
    @village_building.building.building_outputs.each do |output|
      add_resource_to_village(output.resource, output.amount)
    end
  end

  def broadcast_updates
    broadcast_replace_to(
      [@village, :resources],
      target: 'resources-list',
      partial: 'villages/resources_list',
      locals: { village: @village }
    )
  end
end
```

### Benefits
- **Single Responsibility**: Each service handles one business operation
- **Testability**: Easy to unit test business logic
- **Reusability**: Services can be called from controllers, jobs, or other services
- **Maintainability**: Complex logic is isolated and well-organized

## Background Job Pattern

### Overview
Background jobs handle time-consuming operations without blocking the user interface, essential for responsive Rails applications.

### Implementation
```ruby
# app/jobs/village_loop_job.rb
class VillageLoopJob < ApplicationJob
  queue_as :default

  def perform(village_id)
    village = Village.find(village_id)
    VillageLoopService.new(village).call
  end
end

# Recurring job scheduling
# config/recurring.yml
village_loop:
  cron: "*/30 * * * * *"  # Every 30 seconds
  class: PlayLoopJob
```

### Benefits
- **Non-blocking**: UI remains responsive during long operations
- **Reliability**: Jobs are persisted and can be retried on failure
- **Scalability**: Background workers can be scaled independently
- **Scheduling**: Support for recurring and delayed job execution

**[📖 Read the complete Background Jobs documentation →](background-jobs/README.md)**

## Turbo Stream Broadcasting Pattern

### Overview
Real-time UI updates using Turbo Streams for seamless user experience.

### Implementation
```ruby
# In service objects
def broadcast_updates
  broadcast_replace_to(
    [@village, :resources],
    target: 'resources-list',
    partial: 'villages/resources_list',
    locals: { village: @village }
  )
end

# In controllers
def create
  @village_building = @village.village_buildings.build(village_building_params)
  
  if @village_building.save
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @village }
    end
  end
end
```

### Benefits
- **Real-time Updates**: Immediate UI reflection of data changes
- **Partial Updates**: Only affected DOM elements are updated
- **Multi-user Support**: All connected users see updates simultaneously
- **Performance**: Efficient compared to full page reloads

## Factory Pattern for Game Objects

### Overview
Factories create complex game objects with proper initialization and relationships.

### Implementation
```ruby
# spec/factories/villages.rb
FactoryBot.define do
  factory :village do
    name { Faker::Address.community }
    user

    trait :with_resources do
      after(:create) do |village|
        create(:village_resource, village: village, resource: create(:resource, :wood))
        create(:village_resource, village: village, resource: create(:resource, :stone))
      end
    end

    trait :with_buildings do
      after(:create) do |village|
        create(:village_building, village: village, building: create(:building, :house))
      end
    end
  end
end
```

### Benefits
- **Test Consistency**: Reliable test data setup
- **Complex Object Creation**: Handles intricate object relationships
- **Trait System**: Flexible object variations for different test scenarios
- **Maintainability**: Centralized object creation logic

## Repository Pattern (ActiveRecord)

### Overview
ActiveRecord models serve as repositories with custom query methods and scopes.

### Implementation
```ruby
# app/models/village.rb
class Village < ApplicationRecord
  belongs_to :user
  has_many :village_buildings, dependent: :destroy
  has_many :village_resources, dependent: :destroy

  scope :active, -> { where(active: true) }
  scope :with_buildings, -> { joins(:village_buildings) }

  def resource_amount(resource_type)
    village_resources.joins(:resource)
                    .where(resources: { name: resource_type })
                    .sum(:amount)
  end

  def can_afford?(costs)
    costs.all? do |cost|
      resource_amount(cost.resource.name) >= cost.amount
    end
  end
end
```

### Benefits
- **Encapsulation**: Business logic stays with the data
- **Query Optimization**: Custom methods can optimize database queries
- **Domain Logic**: Models understand their business rules
- **Relationships**: Clear data relationships and constraints

## Command Pattern for User Actions

### Overview
Controllers act as command handlers, delegating to appropriate services.

### Implementation
```ruby
# app/controllers/village_buildings_controller.rb
class VillageBuildingsController < ApplicationController
  def create
    @village = current_user.villages.find(params[:village_id])
    @village_building = @village.village_buildings.build(village_building_params)

    if @village_building.save
      BuildingConstructionService.new(@village_building).call
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @village }
      end
    else
      handle_construction_failure
    end
  end

  private

  def village_building_params
    params.require(:village_building).permit(:building_id, :tile_id)
  end
end
```

### Benefits
- **Separation of Concerns**: Controllers handle HTTP, services handle business logic
- **Consistency**: Standardized action handling across controllers
- **Flexibility**: Easy to modify business logic without touching HTTP handling
- **Testing**: Controllers and business logic can be tested separately

## Observer Pattern (Callbacks)

### Overview
Model callbacks and Turbo Stream broadcasting implement the observer pattern.

### Implementation
```ruby
# app/models/village_building.rb
class VillageBuilding < ApplicationRecord
  after_create :broadcast_building_added
  after_update :broadcast_building_updated

  private

  def broadcast_building_added
    broadcast_append_to(
      [village, :buildings],
      target: 'village-buildings',
      partial: 'village_buildings/building',
      locals: { village_building: self }
    )
  end
end
```

### Benefits
- **Automatic Updates**: UI updates happen automatically on data changes
- **Decoupling**: Models don't need to know about UI components
- **Consistency**: All data changes trigger appropriate UI updates
- **Event-Driven**: System responds to state changes naturally

## Detailed Pattern Documentation

### Service Objects
Comprehensive documentation on the Service Objects pattern:
- [Service Objects Overview](service-objects/README.md) - Core concepts and key writings
- [Implementation Examples](service-objects/implementation-examples.md) - Practical code examples from leading practitioners
- [Advanced Patterns](service-objects/advanced-patterns.md) - Concerns, autoloading, proc patterns, application services, and idempotency
- [Coding Drills](service-objects/coding-drills.md) - Original drill documentation
- **[🎯 Hands-On Drills](service-objects/drills/)** - TDD-ready coding exercises (recommended)
- [Critical Analysis](service-objects/critical-analysis.md) - Debates, criticisms, and alternative approaches
- [References](service-objects/references.md) - Complete bibliography and further reading

### Background Jobs
Comprehensive documentation on background job processing patterns:
- [Background Jobs Overview](background-jobs/README.md) - Core concepts, queue strategies, and community insights
- [Implementation Examples](background-jobs/implementation-examples.md) - Practical patterns for job design, error handling, and testing
- [Advanced Patterns](background-jobs/advanced-patterns.md) - Idempotency, workflow orchestration, and distributed coordination
- [Coding Drills](background-jobs/coding-drills.md) - Comprehensive exercises for mastering background job patterns
- [Critical Analysis](background-jobs/critical-analysis.md) - Debates on queue backends, retry strategies, and architectural decisions
- [References](background-jobs/references.md) - Complete bibliography from Rails core team and community experts

## Related Documentation

- [Architecture Overview](../architecture/README.md)
- [Coding Patterns](../coding-patterns/README.md)
- [Background Processing](background-processing.md)
- [Real-Time Updates](real-time-updates.md)
