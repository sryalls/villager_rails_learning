# Service Objects Coding Drills

These hands-on coding exercises will help you master service object patterns and advanced techniques. Each drill builds on the previous ones and includes tests to verify your implementation.

## 🎯 **NEW: Individual Drill Folders**

**The drills have been reorganized into individual folders for better TDD workflow:**

👉 **[Go to Drills Directory](./drills/)** for the new hands-on structure

Each drill now has:
- Individual folder with README describing the problem
- Starter code files to edit
- Complete test files (unaltered) for TDD
- Supporting files (models, migrations) as needed

**Quick Start:**
```bash
# Navigate to any drill and start coding
cd drills/01-basic-service-structure/
bundle exec rspec creation_service_spec.rb
# Edit creation_service.rb to make tests pass
```

---

## Original Drill Documentation

The content below shows the original monolithic drill format. **Use the [individual drill folders](./drills/) for hands-on practice** - they provide a much better TDD experience.

## Drill 1: Basic Service Object Structure

### Exercise: Create a Village Creation Service

**Goal:** Build a service that creates a village with initial resources and buildings.

**Requirements:**
- Include the `ServiceCallable` concern
- Return a result object with success/failure status
- Handle errors gracefully
- Include proper logging

**Starter Code:**
```ruby
# Create this file: app/services/villages/creation_service.rb
module Villages
  class CreationService
    # TODO: Include ServiceCallable concern
    
    def initialize(user, village_params)
      @user = user
      @village_params = village_params
    end
    
    def call
      # TODO: Implement village creation logic
      # 1. Create the village
      # 2. Add initial resources (wood: 100, stone: 50, food: 25)
      # 3. Create a starting building (town hall)
      # 4. Return appropriate result object
    end
    
    private
    
    def create_village
      # TODO: Implement
    end
    
    def add_initial_resources
      # TODO: Implement
    end
    
    def create_starting_buildings
      # TODO: Implement
    end
  end
end
```

**Test to Pass:**
```ruby
# spec/services/villages/creation_service_spec.rb
RSpec.describe Villages::CreationService do
  let(:user) { create(:user) }
  let(:village_params) { { name: "Test Village" } }
  
  describe "#call" do
    subject { described_class.call(user, village_params) }
    
    it "creates a village successfully" do
      expect { subject }.to change(Village, :count).by(1)
    end
    
    it "returns a successful result" do
      expect(subject).to be_success
      expect(subject.village).to be_a(Village)
    end
    
    it "adds initial resources" do
      result = subject
      village = result.village
      
      expect(village.resource_amount("wood")).to eq(100)
      expect(village.resource_amount("stone")).to eq(50)
      expect(village.resource_amount("food")).to eq(25)
    end
    
    it "creates starting buildings" do
      result = subject
      village = result.village
      
      expect(village.buildings.count).to eq(1)
      expect(village.buildings.first.building_type).to eq("town_hall")
    end
  end
  
  describe "error handling" do
    let(:village_params) { { name: "" } } # Invalid name
    
    it "handles validation errors gracefully" do
      result = described_class.call(user, village_params)
      
      expect(result).to be_failure
      expect(result.error).to be_present
    end
  end
end
```

**Solution Hints:**
- Use `ServiceResult.success` and `ServiceResult.failure`
- Wrap operations in a database transaction
- Handle `ActiveRecord::RecordInvalid` exceptions

---

## Drill 2: Service Object with Concerns

### Exercise: Implement Trackable and Cacheable Concerns

**Goal:** Create reusable concerns for service objects that add tracking and caching functionality.

**Requirements:**
- Create a `Trackable` concern that logs service execution
- Create a `Cacheable` concern that caches service results
- Apply both concerns to a resource production service

**Starter Code:**
```ruby
# app/services/concerns/trackable.rb
module Trackable
  extend ActiveSupport::Concern
  
  included do
    # TODO: Add hooks for tracking
  end
  
  private
  
  def track_service_start
    # TODO: Log service start
  end
  
  def track_service_end(result)
    # TODO: Log service completion with result
  end
end

# app/services/concerns/cacheable.rb
module Cacheable
  extend ActiveSupport::Concern
  
  def call_with_cache(cache_key, expires_in: 1.hour)
    # TODO: Implement caching logic
    # Return cached result if available, otherwise call service and cache result
  end
  
  private
  
  def cache_key_for(*args)
    # TODO: Generate cache key from service class and arguments
  end
end

# app/services/resources/production_service.rb
module Resources
  class ProductionService
    include ServiceCallable
    # TODO: Include Trackable and Cacheable concerns
    
    def initialize(village_building)
      @village_building = village_building
    end
    
    def call
      # TODO: Implement with caching
      # Use call_with_cache with appropriate cache key
    end
    
    private
    
    def perform_production
      # TODO: Actual production logic
      # Calculate resources based on building type and level
      # Return ServiceResult with produced resources
    end
  end
end
```

**Test to Pass:**
```ruby
RSpec.describe Resources::ProductionService do
  let(:village_building) { create(:village_building, :with_house) }
  
  describe "tracking" do
    it "logs service execution" do
      expect(Rails.logger).to receive(:info).with(/Started/)
      expect(Rails.logger).to receive(:info).with(/Completed/)
      
      described_class.call(village_building)
    end
  end
  
  describe "caching" do
    it "caches results" do
      service = described_class.new(village_building)
      
      # First call should hit the service
      expect(service).to receive(:perform_production).once.and_call_original
      result1 = service.call
      
      # Second call should use cache
      expect(service).not_to receive(:perform_production)
      result2 = service.call
      
      expect(result1.resources).to eq(result2.resources)
    end
  end
end
```

---

## Drill 3: Proc-based Command Pattern

### Exercise: Build a Village Command System

**Goal:** Create a flexible command system using procs for village operations.

**Requirements:**
- Commands should be defined as procs
- Support undo operations where possible
- Commands should be composable
- Include validation for each command

**Starter Code:**
```ruby
# app/services/villages/command_service.rb
module Villages
  class CommandService
    def initialize(village)
      @village = village
      @command_history = []
    end
    
    def commands
      {
        add_building: build_add_building_command,
        remove_building: build_remove_building_command,
        upgrade_building: build_upgrade_building_command,
        add_resources: build_add_resources_command,
        consume_resources: build_consume_resources_command
      }
    end
    
    def execute(command_name, *args)
      # TODO: Implement command execution with history tracking
    end
    
    def undo_last
      # TODO: Implement undo functionality
    end
    
    def can_undo?
      # TODO: Check if undo is possible
    end
    
    private
    
    def build_add_building_command
      ->(building_type, x, y) {
        # TODO: Implement building addition
        # Return { action: :add_building, data: building, undo: undo_proc }
      }
    end
    
    def build_remove_building_command
      ->(building_id) {
        # TODO: Implement building removal
        # Return { action: :remove_building, data: building, undo: undo_proc }
      }
    end
    
    def build_upgrade_building_command
      ->(building_id) {
        # TODO: Implement building upgrade
        # Return { action: :upgrade_building, data: building, undo: undo_proc }
      }
    end
    
    def build_add_resources_command
      ->(resources_hash) {
        # TODO: Implement resource addition
        # Example: { wood: 10, stone: 5 }
      }
    end
    
    def build_consume_resources_command
      ->(resources_hash) {
        # TODO: Implement resource consumption with validation
        # Should fail if insufficient resources
      }
    end
  end
end
```

**Test to Pass:**
```ruby
RSpec.describe Villages::CommandService do
  let(:village) { create(:village) }
  let(:service) { described_class.new(village) }
  
  describe "building commands" do
    it "adds a building" do
      expect {
        service.execute(:add_building, "house", 2, 3)
      }.to change(village.buildings, :count).by(1)
      
      building = village.buildings.last
      expect(building.building_type).to eq("house")
      expect(building.position_x).to eq(2)
      expect(building.position_y).to eq(3)
    end
    
    it "removes a building" do
      building = create(:building, village: village)
      
      expect {
        service.execute(:remove_building, building.id)
      }.to change(village.buildings, :count).by(-1)
    end
    
    it "upgrades a building" do
      building = create(:building, village: village, level: 1)
      
      service.execute(:upgrade_building, building.id)
      
      expect(building.reload.level).to eq(2)
    end
  end
  
  describe "resource commands" do
    before do
      village.add_resource("wood", 100)
      village.add_resource("stone", 50)
    end
    
    it "adds resources" do
      service.execute(:add_resources, { wood: 10, stone: 5 })
      
      expect(village.resource_amount("wood")).to eq(110)
      expect(village.resource_amount("stone")).to eq(55)
    end
    
    it "consumes resources when sufficient" do
      service.execute(:consume_resources, { wood: 20, stone: 10 })
      
      expect(village.resource_amount("wood")).to eq(80)
      expect(village.resource_amount("stone")).to eq(40)
    end
    
    it "fails to consume resources when insufficient" do
      expect {
        service.execute(:consume_resources, { wood: 200, stone: 10 })
      }.to raise_error(/Insufficient resources/)
    end
  end
  
  describe "undo functionality" do
    it "undoes the last command" do
      service.execute(:add_resources, { wood: 10 })
      expect(village.resource_amount("wood")).to eq(10)
      
      service.undo_last
      expect(village.resource_amount("wood")).to eq(0)
    end
    
    it "tracks command history" do
      service.execute(:add_resources, { wood: 10 })
      service.execute(:add_resources, { stone: 5 })
      
      expect(service.can_undo?).to be true
      
      service.undo_last # Undo stone addition
      expect(village.resource_amount("stone")).to eq(0)
      expect(village.resource_amount("wood")).to eq(10)
    end
  end
end
```

---

## Drill 4: Advanced Result Objects with OpenStruct

### Exercise: Build a Comprehensive Game State Service

**Goal:** Create a service that returns rich result objects with multiple data points and chainable operations.

**Requirements:**
- Use OpenStruct-based result objects
- Support method chaining with `on_success` and `on_failure`
- Include detailed metrics and state information
- Support partial failures

**Starter Code:**
```ruby
# app/services/game/state_update_service.rb
module Game
  class StateUpdateService
    include ServiceCallable
    
    def initialize(village)
      @village = village
      @metrics = {}
      @errors = []
    end
    
    def call
      # TODO: Implement comprehensive state update
      # 1. Update all buildings production
      # 2. Process population changes
      # 3. Handle random events
      # 4. Calculate village score
      # 5. Return detailed result object
    end
    
    private
    
    def update_buildings_production
      # TODO: Process each building's production
      # Track success/failure for each building
    end
    
    def process_population_changes
      # TODO: Handle population growth/decline
    end
    
    def handle_random_events
      # TODO: Process random game events (weather, merchants, etc.)
    end
    
    def calculate_village_score
      # TODO: Calculate overall village performance score
    end
    
    def build_result_object
      # TODO: Create comprehensive OpenStruct result
      # Should include:
      # - success status
      # - village state
      # - production metrics
      # - population changes
      # - events triggered
      # - score changes
      # - any errors or warnings
    end
  end
end

# Enhanced ServiceResult class
class GameStateResult < OpenStruct
  def initialize(success:, **attributes)
    super(success: success, **attributes)
  end
  
  def success?
    success
  end
  
  def failure?
    !success?
  end
  
  def partial_success?
    # TODO: Implement logic for partial success
    # (some operations succeeded, others failed)
  end
  
  def on_success
    yield(self) if success?
    self
  end
  
  def on_failure
    yield(self) if failure?
    self
  end
  
  def on_partial_success
    yield(self) if partial_success?
    self
  end
  
  def summary
    # TODO: Return a human-readable summary of the operation
  end
end
```

**Test to Pass:**
```ruby
RSpec.describe Game::StateUpdateService do
  let(:village) { create(:village, :with_buildings, :with_resources) }
  
  describe "#call" do
    subject { described_class.call(village) }
    
    it "returns a comprehensive result object" do
      expect(subject).to be_a(GameStateResult)
      expect(subject.village).to eq(village)
      expect(subject.production_metrics).to be_present
      expect(subject.population_changes).to be_present
      expect(subject.score_changes).to be_present
    end
    
    it "supports method chaining" do
      notifications_sent = []
      
      result = subject
        .on_success { |r| notifications_sent << "success: #{r.summary}" }
        .on_failure { |r| notifications_sent << "failure: #{r.errors}" }
        .on_partial_success { |r| notifications_sent << "partial: #{r.summary}" }
      
      expect(result).to be_a(GameStateResult)
      expect(notifications_sent).not_to be_empty
    end
    
    context "with building production failures" do
      before do
        # Simulate a building that fails to produce
        allow_any_instance_of(Building).to receive(:produce_resources)
          .and_raise(StandardError, "Production facility damaged")
      end
      
      it "handles partial failures gracefully" do
        expect(subject).to be_partial_success
        expect(subject.errors).not_to be_empty
        expect(subject.production_metrics[:failed_buildings]).to be > 0
      end
    end
  end
  
  describe "result object features" do
    let(:result) { described_class.call(village) }
    
    it "provides detailed metrics" do
      expect(result.production_metrics).to include(:total_resources_produced)
      expect(result.production_metrics).to include(:buildings_processed)
      expect(result.population_changes).to include(:growth_rate)
      expect(result.score_changes).to include(:previous_score)
      expect(result.score_changes).to include(:new_score)
    end
    
    it "generates meaningful summaries" do
      expect(result.summary).to be_a(String)
      expect(result.summary).to include("Village")
      expect(result.summary.length).to be > 20
    end
  end
end
```

---

## Drill 5: Idempotent Background Job Services

### Exercise: Build Idempotent Resource Collection Service

**Goal:** Create a service that can safely run multiple times without side effects, suitable for background job execution.

**Requirements:**
- Implement database-level idempotency using unique constraints
- Handle race conditions gracefully
- Support distributed idempotency with Redis
- Include comprehensive logging and monitoring

**Starter Code:**
```ruby
# app/services/resources/collection_service.rb
module Resources
  class CollectionService
    include ServiceCallable
    
    def initialize(village_id, collection_type = :scheduled)
      @village_id = village_id
      @collection_type = collection_type
      @village = Village.find(@village_id)
    end
    
    def call
      # TODO: Implement idempotent resource collection
      # 1. Generate idempotency key
      # 2. Check for existing collection record
      # 3. Perform collection if not already done
      # 4. Record the operation
    end
    
    private
    
    def generate_idempotency_key
      # TODO: Create unique key based on village, time window, and collection type
      # Should ensure operations within same time window are idempotent
    end
    
    def existing_collection
      # TODO: Check database for existing collection record
    end
    
    def perform_collection
      # TODO: Actual resource collection logic
      # Collect from all buildings, apply bonuses, etc.
    end
    
    def record_collection(resources_collected)
      # TODO: Create database record of the collection operation
    end
    
    def with_distributed_lock(&block)
      # TODO: Implement Redis-based distributed locking
      # Prevent multiple workers from processing same collection
    end
  end
end

# Migration for tracking collections
class CreateResourceCollections < ActiveRecord::Migration[7.0]
  def change
    create_table :resource_collections do |t|
      t.references :village, null: false, foreign_key: true
      t.string :idempotency_key, null: false
      t.string :collection_type, null: false
      t.json :resources_collected
      t.timestamp :collected_at, null: false
      t.timestamps
    end
    
    add_index :resource_collections, :idempotency_key, unique: true
    add_index :resource_collections, [:village_id, :collected_at]
  end
end

# Model for tracking collections
class ResourceCollection < ApplicationRecord
  belongs_to :village
  
  validates :idempotency_key, presence: true, uniqueness: true
  validates :collection_type, presence: true
  validates :collected_at, presence: true
end
```

**Test to Pass:**
```ruby
RSpec.describe Resources::CollectionService do
  let(:village) { create(:village, :with_buildings) }
  let(:service) { described_class.new(village.id) }
  
  describe "idempotency" do
    it "performs collection only once for same time window" do
      # First call should create collection
      result1 = service.call
      expect(result1).to be_success
      
      # Second call should return existing collection
      result2 = service.call
      expect(result2).to be_success
      expect(result2.already_collected).to be true
      
      # Should have only one collection record
      expect(ResourceCollection.count).to eq(1)
    end
    
    it "handles concurrent execution safely" do
      # Simulate multiple workers trying to collect simultaneously
      results = []
      
      threads = 3.times.map do
        Thread.new do
          results << described_class.call(village.id)
        end
      end
      
      threads.each(&:join)
      
      # Only one should succeed in creating new collection
      successful_collections = results.count { |r| r.success? && !r.already_collected }
      expect(successful_collections).to eq(1)
      expect(ResourceCollection.count).to eq(1)
    end
  end
  
  describe "different time windows" do
    it "allows new collection in different time window" do
      # First collection
      result1 = service.call
      expect(result1).to be_success
      
      # Simulate time passing to next collection window
      travel 1.hour do
        result2 = described_class.new(village.id).call
        expect(result2).to be_success
        expect(result2.already_collected).to be_falsy
      end
      
      expect(ResourceCollection.count).to eq(2)
    end
  end
  
  describe "distributed locking" do
    before do
      # Ensure Redis is available for testing
      skip "Redis not available" unless Redis.current.ping == "PONG"
    end
    
    it "prevents race conditions across multiple processes" do
      # This test simulates distributed execution
      # In real scenario, this would be multiple worker processes
      
      lock_acquired_count = 0
      
      3.times do
        service_instance = described_class.new(village.id)
        service_instance.send(:with_distributed_lock) do
          lock_acquired_count += 1
          sleep 0.1 # Simulate work
        end
      end
      
      # Only one should acquire the lock
      expect(lock_acquired_count).to eq(1)
    end
  end
  
  describe "error handling" do
    context "when village is deleted during execution" do
      it "handles missing village gracefully" do
        village.destroy
        
        result = described_class.call(village.id)
        expect(result).to be_failure
        expect(result.error).to include("Village not found")
      end
    end
    
    context "when database constraint violation occurs" do
      it "handles unique constraint violations" do
        # Create a collection record directly to simulate race condition
        ResourceCollection.create!(
          village: village,
          idempotency_key: service.send(:generate_idempotency_key),
          collection_type: "scheduled",
          resources_collected: {},
          collected_at: Time.current
        )
        
        result = service.call
        expect(result).to be_success
        expect(result.already_collected).to be true
      end
    end
  end
end
```

---

## Progressive Difficulty Challenges

### Challenge 1: Service Composition Pipeline
Build a service that chains multiple operations together, with each step depending on the previous one's success.

### Challenge 2: Event-Driven Service Architecture
Create services that communicate through events rather than direct calls.

### Challenge 3: Service Object Middleware
Implement middleware pattern for services (authentication, logging, caching, etc.).

### Challenge 4: Dynamic Service Loading
Build a system that can load and execute services dynamically based on configuration.

### Challenge 5: Distributed Service Coordination
Create services that coordinate across multiple application instances using message queues.

## Practice Schedule

**Week 1:** Drills 1-2 (Basic structure and concerns)
**Week 2:** Drill 3 (Proc-based commands)  
**Week 3:** Drill 4 (Advanced result objects)
**Week 4:** Drill 5 (Idempotency)
**Week 5:** Challenges 1-2
**Week 6:** Challenges 3-5

Each drill should be completed with full test coverage and can be extended with additional features based on your specific needs.

## Tips for Success

1. **Start simple:** Get basic functionality working before adding complexity
2. **Test-driven:** Write tests first to clarify requirements
3. **Incremental:** Build each feature step by step
4. **Review:** Study the solutions of others in the community
5. **Apply:** Use these patterns in your actual Villager Rails project

These drills will give you hands-on experience with all the advanced service object patterns mentioned in your notes!
