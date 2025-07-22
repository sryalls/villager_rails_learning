# Background Jobs Coding Drills

These practical coding exercises will help you master background job patterns, idempotency, error handling, and advanced orchestration techniques. Each drill includes comprehensive tests and builds on previous concepts.

## Drill 1: Basic Idempotent Job

### Exercise: Create an Idempotent Resource Collection Job

**Goal:** Build a job that collects resources from buildings and is safe to run multiple times.

**Requirements:**
- Use database-level idempotency with unique constraints
- Handle concurrent execution gracefully
- Track collection operations for audit purposes
- Include proper error handling and logging

**Starter Code:**
```ruby
# Create migration first
class CreateResourceCollections < ActiveRecord::Migration[7.0]
  def change
    create_table :resource_collections do |t|
      t.references :village, null: false, foreign_key: true
      t.string :collection_period, null: false # e.g., "2024-01-15-14" (year-month-day-hour)
      t.json :resources_collected, default: {}
      t.decimal :total_value, precision: 10, scale: 2, default: 0
      t.timestamp :collected_at, null: false
      t.timestamps
    end
    
    # TODO: Add appropriate indexes for idempotency and performance
  end
end

# Model
class ResourceCollection < ApplicationRecord
  belongs_to :village
  
  # TODO: Add validations for idempotency
  # TODO: Add scopes for querying collections
end

# Job implementation
class IdempotentResourceCollectionJob < ApplicationJob
  queue_as :resource_processing
  
  def perform(village_id)
    @village = Village.find(village_id)
    @collection_period = calculate_collection_period
    
    # TODO: Implement idempotent resource collection
    # 1. Check if collection already exists for this period
    # 2. If not, create collection record
    # 3. Collect resources from all buildings
    # 4. Update village resources
    # 5. Broadcast updates via Turbo Stream
  end
  
  private
  
  def calculate_collection_period
    # TODO: Create period string based on current time
    # Should group collections into 1-hour windows
  end
  
  def existing_collection
    # TODO: Find existing collection for this village and period
  end
  
  def create_collection_record
    # TODO: Create new collection record
    # Handle ActiveRecord::RecordNotUnique gracefully
  end
  
  def collect_resources_from_buildings
    # TODO: Calculate resources from all village buildings
    # Return hash of resource_type => amount
  end
  
  def update_village_resources(resources)
    # TODO: Add collected resources to village
    # Use database transaction for consistency
  end
  
  def broadcast_resource_update
    # TODO: Broadcast Turbo Stream update to update UI
  end
end
```

**Test to Pass:**
```ruby
RSpec.describe IdempotentResourceCollectionJob do
  let(:village) { create(:village, :with_resource_buildings) }
  
  describe "#perform" do
    it "collects resources successfully" do
      expect {
        described_class.perform_now(village.id)
      }.to change(ResourceCollection, :count).by(1)
    end
    
    it "updates village resources" do
      initial_wood = village.resource_amount("wood")
      
      described_class.perform_now(village.id)
      
      expect(village.reload.resource_amount("wood")).to be > initial_wood
    end
    
    it "is idempotent within same collection period" do
      # First execution
      described_class.perform_now(village.id)
      initial_collection_count = ResourceCollection.count
      initial_wood = village.reload.resource_amount("wood")
      
      # Second execution in same period
      described_class.perform_now(village.id)
      
      expect(ResourceCollection.count).to eq(initial_collection_count)
      expect(village.reload.resource_amount("wood")).to eq(initial_wood)
    end
    
    it "allows new collection in different period" do
      # First collection
      described_class.perform_now(village.id)
      
      # Simulate time passing to next collection period
      travel 2.hours do
        expect {
          described_class.perform_now(village.id)
        }.to change(ResourceCollection, :count).by(1)
      end
    end
    
    it "handles concurrent execution safely" do
      # Simulate multiple workers processing simultaneously
      results = []
      
      threads = 3.times.map do
        Thread.new do
          begin
            described_class.perform_now(village.id)
            results << :success
          rescue => e
            results << e.class.name
          end
        end
      end
      
      threads.each(&:join)
      
      # Should have exactly one collection record
      expect(ResourceCollection.count).to eq(1)
      # At least one should succeed
      expect(results).to include(:success)
    end
  end
  
  describe "error handling" do
    it "handles deleted village gracefully" do
      village.destroy
      
      expect {
        described_class.perform_now(village.id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
```

**Success Criteria:**
- All tests pass
- Job is idempotent within same time window
- Handles concurrent execution without duplicates
- Proper error handling and logging

---

## Drill 2: Smart Retry Strategy Job

### Exercise: Build a Job with Intelligent Error Handling

**Goal:** Create a job that handles different types of errors with appropriate retry strategies.

**Requirements:**
- Different retry strategies for different error types
- Circuit breaker pattern for external API failures
- Dead letter queue for permanent failures
- Comprehensive error logging and monitoring

**Starter Code:**
```ruby
# Error classes for different failure types
class TransientError < StandardError; end
class PermanentError < StandardError; end
class ExternalServiceError < StandardError; end
class RateLimitError < StandardError; end

# Circuit breaker state tracking
class CircuitBreakerState < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  
  def open?
    # TODO: Implement logic to determine if circuit is open
    # Based on failure_count and last_failure_at
  end
  
  def should_attempt_reset?
    # TODO: Implement logic for attempting circuit reset
    # After timeout period has passed
  end
  
  def record_success
    # TODO: Reset failure count on success
  end
  
  def record_failure
    # TODO: Increment failure count and update last_failure_at
  end
end

class SmartRetryJob < ApplicationJob
  queue_as :default
  
  # TODO: Configure different retry strategies for different errors
  # - TransientError: exponential backoff, 5 attempts
  # - RateLimitError: fixed delay, 3 attempts
  # - ExternalServiceError: custom circuit breaker logic
  # - PermanentError: no retry, send to dead letter queue
  
  def perform(operation_type, *args)
    case operation_type
    when 'external_api_call'
      perform_external_api_call(*args)
    when 'database_operation'
      perform_database_operation(*args)
    when 'file_processing'
      perform_file_processing(*args)
    else
      raise ArgumentError, "Unknown operation type: #{operation_type}"
    end
  end
  
  private
  
  def perform_external_api_call(api_endpoint, data)
    # TODO: Implement with circuit breaker protection
    # Simulate different types of API failures
    with_circuit_breaker("external_api") do
      simulate_api_call(api_endpoint, data)
    end
  end
  
  def perform_database_operation(table_name, operation, data)
    # TODO: Implement database operation with appropriate error handling
    # Simulate deadlocks, connection issues, constraint violations
    simulate_database_operation(table_name, operation, data)
  end
  
  def perform_file_processing(file_path, processing_type)
    # TODO: Implement file processing with error handling
    # Simulate file not found, permission errors, corruption
    simulate_file_processing(file_path, processing_type)
  end
  
  def with_circuit_breaker(name)
    # TODO: Implement circuit breaker logic
    # 1. Check if circuit is open
    # 2. If open and not ready for reset, raise CircuitBreakerOpen
    # 3. Execute operation
    # 4. Record success/failure
  end
  
  def simulate_api_call(endpoint, data)
    # TODO: Simulate various API responses
    # - Success (80% of time)
    # - Rate limit error (10% of time)
    # - Server error (5% of time)  
    # - Network timeout (5% of time)
  end
  
  def simulate_database_operation(table_name, operation, data)
    # TODO: Simulate database operations with potential failures
    # - Success (90% of time)
    # - Deadlock (5% of time)
    # - Constraint violation (3% of time)
    # - Connection timeout (2% of time)
  end
  
  def simulate_file_processing(file_path, processing_type)
    # TODO: Simulate file processing scenarios
    # - Success (85% of time)
    # - File not found (10% of time) - permanent error
    # - Permission denied (3% of time) - retry after delay
    # - Disk full (2% of time) - transient error
  end
  
  def send_to_dead_letter_queue(error, *args)
    # TODO: Implement dead letter queue logic
    # Store failed job details for manual review
  end
  
  def calculate_retry_delay(error_type, attempt_number)
    # TODO: Calculate appropriate delay based on error type and attempt
  end
end

# Dead letter queue model
class DeadLetterJob < ApplicationRecord
  # TODO: Define schema for storing permanently failed jobs
end
```

**Test to Pass:**
```ruby
RSpec.describe SmartRetryJob do
  describe "retry strategies" do
    context "with transient errors" do
      it "retries with exponential backoff" do
        # Mock to always fail with transient error
        allow_any_instance_of(described_class)
          .to receive(:simulate_database_operation)
          .and_raise(TransientError, "Temporary database issue")
        
        expect {
          described_class.perform_now('database_operation', 'users', 'insert', {})
        }.to raise_error(TransientError)
        
        # Should have attempted multiple retries
        # Check job retry count or execution logs
      end
    end
    
    context "with rate limit errors" do
      it "retries with fixed delay" do
        # TODO: Test rate limit retry behavior
      end
    end
    
    context "with permanent errors" do
      it "sends to dead letter queue without retry" do
        allow_any_instance_of(described_class)
          .to receive(:simulate_file_processing)
          .and_raise(PermanentError, "File does not exist")
        
        expect {
          described_class.perform_now('file_processing', '/nonexistent', 'parse')
        }.to change(DeadLetterJob, :count).by(1)
      end
    end
  end
  
  describe "circuit breaker" do
    context "when external service is failing" do
      it "opens circuit after threshold failures" do
        # TODO: Test circuit breaker opening
      end
      
      it "attempts reset after timeout" do
        # TODO: Test circuit breaker reset logic
      end
    end
  end
  
  describe "error monitoring" do
    it "logs errors with appropriate context" do
      # TODO: Test error logging and monitoring
    end
  end
end
```

---

## Drill 3: Job Orchestration Workflow

### Exercise: Build a Multi-Step Workflow System

**Goal:** Create a workflow system that orchestrates multiple jobs in sequence with proper state management.

**Requirements:**
- Support for sequential and parallel job execution
- Workflow state persistence and recovery
- Conditional step execution based on previous results
- Rollback capability for failed workflows

**Starter Code:**
```ruby
# Workflow definition and state management
class GameWorkflow < ApplicationRecord
  enum status: { pending: 0, running: 1, completed: 2, failed: 3, rolled_back: 4 }
  
  serialize :context, JSON
  serialize :step_results, JSON
  
  validates :workflow_type, presence: true
  
  def current_step
    # TODO: Determine current step based on completed_steps
  end
  
  def can_execute_step?(step_name)
    # TODO: Check if step can be executed based on workflow state
  end
  
  def record_step_completion(step_name, result)
    # TODO: Record step completion and result
  end
  
  def record_step_failure(step_name, error)
    # TODO: Record step failure
  end
  
  def rollback_step(step_name)
    # TODO: Execute rollback logic for specific step
  end
end

# Workflow orchestrator job
class WorkflowOrchestratorJob < ApplicationJob
  queue_as :workflow_processing
  
  def perform(workflow_id)
    @workflow = GameWorkflow.find(workflow_id)
    
    # TODO: Implement workflow execution logic
    # 1. Determine next step to execute
    # 2. Check step prerequisites
    # 3. Execute step job
    # 4. Handle step completion/failure
    # 5. Schedule next step or complete workflow
  end
  
  private
  
  def workflow_definitions
    {
      'village_creation' => {
        steps: [
          { name: 'validate_input', job: ValidateVillageInputJob, parallel: false },
          { name: 'create_village', job: CreateVillageJob, parallel: false },
          { name: 'setup_resources', job: SetupVillageResourcesJob, parallel: true },
          { name: 'create_buildings', job: CreateInitialBuildingsJob, parallel: true },
          { name: 'notify_completion', job: NotifyVillageCreationJob, parallel: false }
        ]
      },
      'village_upgrade' => {
        steps: [
          { name: 'validate_upgrade', job: ValidateUpgradeJob, parallel: false },
          { name: 'consume_resources', job: ConsumeResourcesJob, parallel: false },
          { name: 'upgrade_buildings', job: UpgradeBuildingsJob, parallel: true },
          { name: 'update_stats', job: UpdateVillageStatsJob, parallel: false },
          { name: 'broadcast_changes', job: BroadcastVillageChangesJob, parallel: false }
        ]
      }
    }
  end
  
  def execute_step(step_definition)
    # TODO: Execute individual workflow step
    # Handle both sequential and parallel execution
  end
  
  def execute_parallel_steps(steps)
    # TODO: Execute multiple steps in parallel
    # Wait for all to complete before proceeding
  end
  
  def handle_step_success(step_name, result)
    # TODO: Handle successful step completion
  end
  
  def handle_step_failure(step_name, error)
    # TODO: Handle step failure and determine rollback strategy
  end
  
  def should_rollback?(step_name, error)
    # TODO: Determine if workflow should be rolled back
  end
  
  def execute_rollback
    # TODO: Execute rollback steps in reverse order
  end
end

# Individual workflow step jobs
class ValidateVillageInputJob < ApplicationJob
  def perform(workflow_context)
    # TODO: Implement input validation
    # Return structured result with validation details
  end
end

class CreateVillageJob < ApplicationJob
  def perform(workflow_context)
    # TODO: Implement village creation
  end
end

class SetupVillageResourcesJob < ApplicationJob
  def perform(workflow_context)
    # TODO: Setup initial village resources
  end
end

class CreateInitialBuildingsJob < ApplicationJob
  def perform(workflow_context)
    # TODO: Create starting buildings
  end
end

class NotifyVillageCreationJob < ApplicationJob
  def perform(workflow_context)
    # TODO: Send completion notifications
  end
end

# Workflow starter service
class WorkflowService
  def self.start_workflow(workflow_type, initial_context = {})
    # TODO: Create workflow record and start orchestration
  end
  
  def self.resume_workflow(workflow_id)
    # TODO: Resume failed or paused workflow
  end
  
  def self.cancel_workflow(workflow_id)
    # TODO: Cancel running workflow with cleanup
  end
end
```

**Test to Pass:**
```ruby
RSpec.describe WorkflowOrchestratorJob do
  let(:workflow_context) { { user_id: 1, village_name: "Test Village" } }
  
  describe "village creation workflow" do
    let(:workflow) { GameWorkflow.create!(workflow_type: 'village_creation', context: workflow_context) }
    
    it "executes all steps in sequence" do
      # Mock all step jobs to succeed
      allow(ValidateVillageInputJob).to receive(:perform_now).and_return(success_result)
      allow(CreateVillageJob).to receive(:perform_now).and_return(success_result)
      allow(SetupVillageResourcesJob).to receive(:perform_now).and_return(success_result)
      allow(CreateInitialBuildingsJob).to receive(:perform_now).and_return(success_result)
      allow(NotifyVillageCreationJob).to receive(:perform_now).and_return(success_result)
      
      described_class.perform_now(workflow.id)
      
      expect(workflow.reload.status).to eq('completed')
      expect(workflow.completed_steps.count).to eq(5)
    end
    
    it "handles step failures with rollback" do
      # Mock first step to succeed, second to fail
      allow(ValidateVillageInputJob).to receive(:perform_now).and_return(success_result)
      allow(CreateVillageJob).to receive(:perform_now).and_raise(StandardError, "Creation failed")
      
      described_class.perform_now(workflow.id)
      
      expect(workflow.reload.status).to eq('failed')
      # Should have rolled back any completed steps
    end
    
    it "executes parallel steps concurrently" do
      # TODO: Test parallel step execution
      # Verify that setup_resources and create_buildings run in parallel
    end
  end
  
  describe "workflow recovery" do
    it "resumes from last completed step" do
      # TODO: Test workflow resumption after failure
    end
  end
  
  describe "workflow cancellation" do
    it "cancels running workflow and cleans up" do
      # TODO: Test workflow cancellation
    end
  end
  
  private
  
  def success_result
    OpenStruct.new(success?: true, data: {})
  end
end
```

---

## Drill 4: Performance-Optimized Batch Processing

### Exercise: Build High-Performance Batch Job

**Goal:** Create a job that efficiently processes large datasets with memory management and parallel processing.

**Requirements:**
- Memory-efficient processing of large datasets
- Parallel processing with thread safety
- Progress tracking and resumability
- Performance monitoring and optimization

**Starter Code:**
```ruby
# Batch processing job with performance optimizations
class PerformanceBatchJob < ApplicationJob
  queue_as :batch_processing
  
  # Performance monitoring
  around_perform do |job, block|
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    start_memory = get_memory_usage
    
    result = block.call
    
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end_memory = get_memory_usage
    
    log_performance_metrics(
      duration: end_time - start_time,
      memory_delta: end_memory - start_memory,
      items_processed: @items_processed || 0
    )
    
    result
  end
  
  def perform(batch_id, options = {})
    @batch = ProcessingBatch.find(batch_id)
    @options = default_options.merge(options)
    @items_processed = 0
    
    # TODO: Implement high-performance batch processing
    # 1. Initialize progress tracking
    # 2. Process items in optimized batches
    # 3. Use parallel processing where appropriate
    # 4. Manage memory usage
    # 5. Handle errors gracefully
    # 6. Update progress regularly
  end
  
  private
  
  def default_options
    {
      batch_size: 1000,
      thread_count: [Concurrent.processor_count, 4].min,
      memory_limit_mb: 500,
      progress_update_interval: 100
    }
  end
  
  def process_in_batches
    # TODO: Implement memory-efficient batch processing
    # Use find_in_batches to avoid loading entire dataset
  end
  
  def process_batch_parallel(items)
    # TODO: Process batch items in parallel using thread pool
    # Ensure thread safety and error handling
  end
  
  def process_single_item(item)
    # TODO: Process individual item
    # Include error handling for single item failures
  end
  
  def should_run_gc?
    # TODO: Determine when to run garbage collection
    # Based on memory usage and processed item count
  end
  
  def memory_usage_exceeds_limit?
    # TODO: Check if memory usage exceeds configured limit
  end
  
  def update_progress
    # TODO: Update batch progress in database
    # Include items processed, success rate, estimated completion
  end
  
  def get_memory_usage
    # TODO: Get current memory usage in MB
  end
  
  def log_performance_metrics(metrics)
    # TODO: Log performance metrics for monitoring
  end
end

# Batch progress tracking
class BatchProgress < ApplicationRecord
  belongs_to :processing_batch
  
  def completion_percentage
    # TODO: Calculate completion percentage
  end
  
  def estimated_completion_time
    # TODO: Estimate completion time based on current rate
  end
  
  def items_per_second
    # TODO: Calculate processing rate
  end
end

# Thread-safe batch processing
class ThreadSafeBatchProcessor
  def initialize(items, thread_count:)
    @items = items
    @thread_count = thread_count
    @results = Concurrent::Array.new
    @errors = Concurrent::Array.new
  end
  
  def process(&block)
    # TODO: Implement thread-safe parallel processing
    # Use thread pool to process items
    # Collect results and errors safely
  end
  
  private
  
  def create_thread_pool
    # TODO: Create and configure thread pool
  end
  
  def process_item_safely(item, &block)
    # TODO: Process item with error handling
  end
end
```

**Test to Pass:**
```ruby
RSpec.describe PerformanceBatchJob do
  let(:large_batch) { create(:processing_batch, :with_large_dataset) } # 10,000 items
  
  describe "performance characteristics" do
    it "processes large batches efficiently" do
      start_time = Time.current
      
      described_class.perform_now(large_batch.id)
      
      duration = Time.current - start_time
      expect(duration).to be < 60.seconds # Should complete within 1 minute
    end
    
    it "manages memory usage effectively" do
      # Monitor memory usage during processing
      memory_samples = []
      
      thread = Thread.new do
        10.times do
          memory_samples << get_current_memory_usage
          sleep 0.5
        end
      end
      
      described_class.perform_now(large_batch.id)
      thread.join
      
      # Memory should not grow unbounded
      expect(memory_samples.max - memory_samples.min).to be < 100.megabytes
    end
    
    it "processes items in parallel" do
      # TODO: Verify parallel processing is occurring
      # Check that multiple threads are being used
    end
  end
  
  describe "progress tracking" do
    it "updates progress regularly" do
      expect {
        described_class.perform_now(large_batch.id)
      }.to change { large_batch.reload.progress_percentage }.from(0).to(100)
    end
    
    it "provides accurate completion estimates" do
      # TODO: Test progress estimation accuracy
    end
  end
  
  describe "error handling" do
    it "continues processing despite individual item failures" do
      # TODO: Test resilience to individual item failures
    end
    
    it "tracks failed items for retry" do
      # TODO: Test failed item tracking
    end
  end
  
  describe "resumability" do
    it "can resume from last processed item" do
      # TODO: Test job resumption after interruption
    end
  end
  
  private
  
  def get_current_memory_usage
    `ps -o rss= -p #{Process.pid}`.to_i * 1024 # KB to bytes
  end
end
```

---

## Drill 5: Distributed Job Coordination

### Exercise: Build Cross-Instance Job Coordination

**Goal:** Create jobs that coordinate across multiple application instances using Redis for distributed locking and state management.

**Requirements:**
- Distributed locking to prevent duplicate execution
- Leader election for singleton jobs
- Cross-instance communication and coordination
- Graceful handling of instance failures

**Starter Code:**
```ruby
# Distributed coordination utilities
class DistributedCoordinator
  def initialize(redis = Redis.current)
    @redis = redis
  end
  
  def with_distributed_lock(key, ttl: 300, &block)
    # TODO: Implement distributed locking with Redis
    # 1. Attempt to acquire lock
    # 2. Execute block if lock acquired
    # 3. Ensure lock is released
  end
  
  def elect_leader(group_name, ttl: 60)
    # TODO: Implement leader election
    # Return true if this instance becomes leader
  end
  
  def is_leader?(group_name)
    # TODO: Check if this instance is current leader
  end
  
  def send_coordination_message(channel, message)
    # TODO: Send message to other instances via Redis pub/sub
  end
  
  def subscribe_to_coordination(channel, &block)
    # TODO: Subscribe to coordination messages
  end
  
  private
  
  def instance_id
    @instance_id ||= "#{Socket.gethostname}:#{Process.pid}"
  end
end

# Singleton job that runs only on one instance
class SingletonGameLoopJob < ApplicationJob
  include DistributedCoordination
  
  def perform
    # TODO: Implement singleton job execution
    # 1. Attempt leader election
    # 2. If leader, execute game loop logic
    # 3. Coordinate with other instances
    # 4. Handle leader failover
  end
  
  private
  
  def execute_as_leader
    # TODO: Execute leader-specific logic
    # Process global game state, schedule instance-specific jobs
  end
  
  def coordinate_with_followers
    # TODO: Send coordination messages to follower instances
  end
  
  def handle_leader_failure
    # TODO: Handle scenario where leader instance fails
  end
end

# Cross-instance batch coordination
class DistributedBatchJob < ApplicationJob
  include DistributedCoordination
  
  def perform(batch_id)
    @batch = DistributedBatch.find(batch_id)
    
    # TODO: Implement distributed batch processing
    # 1. Coordinate work distribution across instances
    # 2. Handle instance failures gracefully
    # 3. Ensure no work is lost or duplicated
    # 4. Collect results from all instances
  end
  
  private
  
  def claim_work_chunk
    # TODO: Atomically claim a chunk of work from the batch
  end
  
  def process_work_chunk(chunk)
    # TODO: Process assigned work chunk
  end
  
  def report_chunk_completion(chunk_id, results)
    # TODO: Report completion to coordination system
  end
  
  def coordinate_batch_completion
    # TODO: Coordinate final batch completion across instances
  end
end

# Distributed state management
class DistributedBatch < ApplicationRecord
  def claim_next_chunk(instance_id, chunk_size: 100)
    # TODO: Atomically claim next available chunk of work
    # Use Redis for coordination between instances
  end
  
  def mark_chunk_completed(chunk_id, instance_id, results)
    # TODO: Mark chunk as completed and store results
  end
  
  def all_chunks_completed?
    # TODO: Check if all work chunks have been completed
  end
  
  def failed_chunks
    # TODO: Get list of chunks that failed processing
  end
  
  def redistribute_failed_chunks
    # TODO: Make failed chunks available for retry by other instances
  end
end

# Coordination concern for jobs
module DistributedCoordination
  extend ActiveSupport::Concern
  
  def coordinator
    @coordinator ||= DistributedCoordinator.new
  end
  
  def with_coordination_lock(key, &block)
    coordinator.with_distributed_lock("job_coordination:#{key}", &block)
  end
  
  def attempt_leadership(group)
    coordinator.elect_leader("job_leader:#{group}")
  end
  
  def broadcast_to_instances(channel, message)
    coordinator.send_coordination_message(channel, message.merge(
      sender: instance_identifier,
      timestamp: Time.current.to_f
    ))
  end
  
  private
  
  def instance_identifier
    "#{Socket.gethostname}:#{Process.pid}"
  end
end
```

**Test to Pass:**
```ruby
RSpec.describe "Distributed Job Coordination" do
  before do
    # Ensure Redis is available for testing
    skip "Redis not available" unless Redis.current.ping == "PONG"
    Redis.current.flushdb # Clean slate for each test
  end
  
  describe SingletonGameLoopJob do
    it "elects a leader among multiple instances" do
      # Simulate multiple instances trying to become leader
      leaders = []
      
      3.times do |i|
        # Simulate different instances with different IDs
        allow(Socket).to receive(:gethostname).and_return("host#{i}")
        allow(Process).to receive(:pid).and_return(1000 + i)
        
        job = described_class.new
        leaders << job.send(:attempt_leadership, "game_loop")
      end
      
      # Only one should become leader
      expect(leaders.count(true)).to eq(1)
    end
    
    it "handles leader failover" do
      # TODO: Test leader failover scenario
      # 1. Establish leader
      # 2. Simulate leader failure (expire Redis key)
      # 3. Verify new leader is elected
    end
  end
  
  describe DistributedBatchJob do
    let(:batch) { create(:distributed_batch, :with_large_dataset) }
    
    it "distributes work across multiple instances" do
      # Simulate multiple instances processing the same batch
      processed_chunks = []
      
      3.times do |i|
        # Simulate different instances
        allow(Socket).to receive(:gethostname).and_return("worker#{i}")
        
        job = described_class.new
        chunk = batch.claim_next_chunk("worker#{i}")
        processed_chunks << chunk if chunk
      end
      
      # Each instance should get different chunks
      expect(processed_chunks.map(&:id).uniq.length).to eq(processed_chunks.length)
    end
    
    it "handles instance failures gracefully" do
      # TODO: Test handling of instance failures
      # 1. Assign work to instance
      # 2. Simulate instance failure (don't report completion)
      # 3. Verify work is redistributed
    end
  end
  
  describe DistributedCoordinator do
    let(:coordinator) { described_class.new }
    
    describe "distributed locking" do
      it "prevents concurrent execution" do
        lock_acquired_count = 0
        
        threads = 3.times.map do
          Thread.new do
            coordinator.with_distributed_lock("test_lock") do
              lock_acquired_count += 1
              sleep 0.1
            end
          end
        end
        
        threads.each(&:join)
        
        # Only one thread should acquire the lock
        expect(lock_acquired_count).to eq(1)
      end
      
      it "releases locks after execution" do
        coordinator.with_distributed_lock("test_lock") do
          # Lock should be held
        end
        
        # Lock should be released, allowing new acquisition
        expect(coordinator.with_distributed_lock("test_lock") { true }).to be true
      end
    end
    
    describe "leader election" do
      it "maintains single leader" do
        leaders = []
        
        5.times do |i|
          # Different coordinator instances
          coord = described_class.new
          allow(coord).to receive(:instance_id).and_return("instance_#{i}")
          leaders << coord.elect_leader("test_group")
        end
        
        expect(leaders.count(true)).to eq(1)
      end
    end
  end
end
```

## Advanced Challenge: Event-Driven Job Architecture

### Challenge: Build Event-Driven Job System

Create a system where jobs communicate through events rather than direct scheduling, implementing:

- Event bus for job communication
- Event sourcing for audit trails
- Saga pattern for distributed transactions
- Event replay capability for debugging

## Practice Schedule

**Week 1:** Drill 1 - Basic Idempotent Jobs
**Week 2:** Drill 2 - Smart Retry Strategies  
**Week 3:** Drill 3 - Workflow Orchestration
**Week 4:** Drill 4 - Performance Batch Processing
**Week 5:** Drill 5 - Distributed Coordination
**Week 6:** Advanced Challenge

## Success Metrics

For each drill, aim for:
- ✅ All tests passing
- ✅ Code coverage > 90%
- ✅ Performance benchmarks met
- ✅ Error scenarios handled gracefully
- ✅ Documentation and comments complete

These drills will give you deep, practical experience with advanced background job patterns that are essential for production Rails applications!
