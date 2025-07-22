# Advanced Background Job Patterns

This document explores advanced background job patterns, including idempotency for job safety, complex error handling strategies, job orchestration patterns, and performance optimization techniques.

## Job Idempotency Patterns

### Database-Level Idempotency

Jobs that modify data should be safe to run multiple times:

```ruby
class IdempotentGameLoopJob < ApplicationJob
  def perform(village_id, loop_iteration)
    village = Village.find(village_id)
    
    # Use unique constraint to ensure one loop per iteration
    loop_record = GameLoop.create!(
      village_id: village_id,
      iteration: loop_iteration,
      status: 'processing',
      started_at: Time.current
    )
    
    begin
      process_game_loop(village, loop_iteration)
      loop_record.update!(status: 'completed', completed_at: Time.current)
    rescue => error
      loop_record.update!(status: 'failed', error_message: error.message)
      raise
    end
  rescue ActiveRecord::RecordNotUnique
    # Loop already processed or in progress
    Rails.logger.info "Game loop #{loop_iteration} for village #{village_id} already processed"
  end
  
  private
  
  def process_game_loop(village, iteration)
    # Actual game processing logic
    village.update_resources
    village.process_buildings
    village.handle_events
  end
end

# Migration for tracking game loops
class CreateGameLoops < ActiveRecord::Migration[7.0]
  def change
    create_table :game_loops do |t|
      t.references :village, null: false, foreign_key: true
      t.integer :iteration, null: false
      t.string :status, null: false
      t.text :error_message
      t.timestamp :started_at
      t.timestamp :completed_at
      t.timestamps
    end
    
    add_index :game_loops, [:village_id, :iteration], unique: true
  end
end
```

### Cache-Based Idempotency

For jobs that generate computed results:

```ruby
class IdempotentReportJob < ApplicationJob
  def perform(user_id, report_type, date)
    cache_key = "report:#{user_id}:#{report_type}:#{date}"
    
    # Check if report already generated
    existing_report = Rails.cache.read(cache_key)
    return existing_report if existing_report
    
    # Generate report
    report = generate_report(user_id, report_type, date)
    
    # Cache for 24 hours
    Rails.cache.write(cache_key, report, expires_in: 24.hours)
    
    # Store in database for persistence
    Report.create!(
      user_id: user_id,
      report_type: report_type,
      date: date,
      data: report
    )
    
    report
  end
  
  private
  
  def generate_report(user_id, report_type, date)
    case report_type
    when 'village_stats'
      VillageStatsService.new(user_id, date).call
    when 'resource_summary'
      ResourceSummaryService.new(user_id, date).call
    else
      raise ArgumentError, "Unknown report type: #{report_type}"
    end
  end
end
```

### Distributed Idempotency with Redis

For jobs that need coordination across multiple workers:

```ruby
class DistributedIdempotentJob < ApplicationJob
  def perform(operation_id, *args)
    redis_key = "job_lock:#{operation_id}"
    
    # Try to acquire lock with expiration
    lock_acquired = Redis.current.set(redis_key, "processing", nx: true, ex: 300)
    
    unless lock_acquired
      # Check if operation completed
      if operation_completed?(operation_id)
        Rails.logger.info "Operation #{operation_id} already completed"
        return
      else
        raise "Operation #{operation_id} is being processed by another worker"
      end
    end
    
    begin
      result = perform_operation(operation_id, *args)
      mark_operation_completed(operation_id, result)
      result
    ensure
      Redis.current.del(redis_key)
    end
  end
  
  private
  
  def operation_completed?(operation_id)
    OperationLog.exists?(operation_id: operation_id, status: 'completed')
  end
  
  def mark_operation_completed(operation_id, result)
    OperationLog.create!(
      operation_id: operation_id,
      status: 'completed',
      result: result,
      completed_at: Time.current
    )
  end
  
  def perform_operation(operation_id, *args)
    # Actual operation logic
  end
end
```

## Advanced Error Handling Strategies

### Circuit Breaker Pattern for External APIs

```ruby
class ExternalAPIJob < ApplicationJob
  include CircuitBreaker
  
  circuit_breaker_config(
    failure_threshold: 5,
    recovery_timeout: 60.seconds,
    exceptions: [Net::TimeoutError, Net::HTTPError]
  )
  
  def perform(api_action, *args)
    with_circuit_breaker("external_api") do
      perform_api_call(api_action, *args)
    end
  rescue CircuitBreakerOpen => e
    # API is down, schedule for retry later
    self.class.set(wait: 5.minutes).perform_later(api_action, *args)
    Rails.logger.warn "API circuit breaker open, retrying in 5 minutes"
  end
  
  private
  
  def perform_api_call(action, *args)
    case action
    when 'sync_player_data'
      ExternalGameAPI.sync_player(*args)
    when 'submit_score'
      ExternalGameAPI.submit_score(*args)
    else
      raise ArgumentError, "Unknown API action: #{action}"
    end
  end
end

# Circuit breaker implementation
module CircuitBreaker
  extend ActiveSupport::Concern
  
  class CircuitBreakerOpen < StandardError; end
  
  included do
    class_attribute :circuit_breaker_options
  end
  
  class_methods do
    def circuit_breaker_config(options)
      self.circuit_breaker_options = options
    end
  end
  
  def with_circuit_breaker(name)
    breaker = CircuitBreakerState.find_or_create_by(name: name)
    
    if breaker.open? && !breaker.should_attempt_reset?
      raise CircuitBreakerOpen, "Circuit breaker #{name} is open"
    end
    
    begin
      result = yield
      breaker.record_success
      result
    rescue *circuit_breaker_options[:exceptions] => e
      breaker.record_failure
      raise
    end
  end
end
```

### Graduated Retry Strategy

```ruby
class SmartRetryJob < ApplicationJob
  # Different retry strategies for different error types
  retry_on Net::TimeoutError, wait: :exponentially_longer, attempts: 5
  retry_on ActiveRecord::Deadlocked, wait: 1.second, attempts: 3
  retry_on Redis::CannotConnectError, wait: 30.seconds, attempts: 10
  
  # Custom retry logic
  rescue_from StandardError do |exception|
    case exception
    when Net::HTTPBadRequest
      # Don't retry 4xx errors
      discard_job
    when Net::HTTPServerError
      # Retry 5xx errors with custom logic
      retry_with_backoff(exception)
    else
      # Default retry behavior
      raise exception
    end
  end
  
  def perform(action, *args)
    case action
    when 'process_payment'
      process_payment(*args)
    when 'send_notification'
      send_notification(*args)
    when 'sync_data'
      sync_data(*args)
    end
  end
  
  private
  
  def retry_with_backoff(exception)
    attempt_number = (executions || 0) + 1
    max_attempts = 5
    
    if attempt_number <= max_attempts
      delay = calculate_backoff_delay(attempt_number)
      self.class.set(wait: delay).perform_later(*arguments)
      Rails.logger.warn "Retrying job (attempt #{attempt_number}/#{max_attempts}) in #{delay} seconds: #{exception.message}"
    else
      Rails.logger.error "Job failed after #{max_attempts} attempts: #{exception.message}"
      raise exception
    end
  end
  
  def calculate_backoff_delay(attempt)
    # Exponential backoff with jitter
    base_delay = 2 ** attempt
    jitter = rand(0.5..1.5)
    (base_delay * jitter).seconds
  end
  
  def discard_job
    Rails.logger.error "Discarding job due to permanent failure: #{job_id}"
    # Optionally notify monitoring system
    ErrorTracker.notify("Job permanently failed", job_class: self.class.name)
  end
end
```

## Job Orchestration Patterns

### Workflow Orchestrator

```ruby
class WorkflowOrchestratorJob < ApplicationJob
  def perform(workflow_id)
    workflow = Workflow.find(workflow_id)
    
    case workflow.current_step
    when 'validate_input'
      execute_step(workflow, ValidateInputJob)
    when 'process_data'
      execute_step(workflow, ProcessDataJob)
    when 'generate_output'
      execute_step(workflow, GenerateOutputJob)
    when 'notify_completion'
      execute_step(workflow, NotifyCompletionJob)
    else
      workflow.mark_completed!
    end
  end
  
  private
  
  def execute_step(workflow, job_class)
    begin
      result = job_class.perform_now(workflow.data)
      
      if result.success?
        workflow.advance_to_next_step!
        # Schedule next step
        WorkflowOrchestratorJob.perform_later(workflow.id)
      else
        workflow.mark_failed!(result.error)
      end
    rescue => error
      workflow.mark_failed!(error.message)
      raise
    end
  end
end

# Workflow model for tracking state
class Workflow < ApplicationRecord
  enum status: { pending: 0, processing: 1, completed: 2, failed: 3 }
  
  STEPS = %w[validate_input process_data generate_output notify_completion].freeze
  
  def current_step
    STEPS[step_index] if step_index < STEPS.length
  end
  
  def advance_to_next_step!
    update!(step_index: step_index + 1)
  end
  
  def mark_completed!
    update!(status: 'completed', completed_at: Time.current)
  end
  
  def mark_failed!(error_message)
    update!(status: 'failed', error_message: error_message)
  end
end
```

### Parent-Child Job Pattern

```ruby
class ParentProcessorJob < ApplicationJob
  def perform(batch_id)
    batch = ProcessingBatch.find(batch_id)
    
    # Create child jobs for each item
    child_jobs = batch.items.map do |item|
      ChildProcessorJob.perform_later(item.id, batch_id)
    end
    
    # Create completion job that waits for all children
    BatchCompletionJob.set(wait: 1.minute).perform_later(batch_id, child_jobs.map(&:job_id))
  end
end

class ChildProcessorJob < ApplicationJob
  def perform(item_id, batch_id)
    item = ProcessingItem.find(item_id)
    batch = ProcessingBatch.find(batch_id)
    
    begin
      result = process_item(item)
      
      # Record completion
      JobCompletion.create!(
        batch_id: batch_id,
        item_id: item_id,
        job_id: job_id,
        status: 'completed',
        result: result
      )
    rescue => error
      JobCompletion.create!(
        batch_id: batch_id,
        item_id: item_id,
        job_id: job_id,
        status: 'failed',
        error: error.message
      )
      raise
    end
  end
  
  private
  
  def process_item(item)
    # Individual item processing logic
  end
end

class BatchCompletionJob < ApplicationJob
  def perform(batch_id, child_job_ids)
    batch = ProcessingBatch.find(batch_id)
    
    # Check if all child jobs completed
    completed_jobs = JobCompletion.where(batch_id: batch_id).count
    total_items = batch.items.count
    
    if completed_jobs == total_items
      # All jobs completed, finalize batch
      finalize_batch(batch)
    else
      # Some jobs still pending, check again later
      self.class.set(wait: 30.seconds).perform_later(batch_id, child_job_ids)
    end
  end
  
  private
  
  def finalize_batch(batch)
    failed_jobs = JobCompletion.where(batch_id: batch.id, status: 'failed').count
    
    if failed_jobs == 0
      batch.update!(status: 'completed', completed_at: Time.current)
      BatchSuccessNotificationJob.perform_later(batch.id)
    else
      batch.update!(status: 'partial_failure', completed_at: Time.current)
      BatchFailureNotificationJob.perform_later(batch.id, failed_jobs)
    end
  end
end
```

## Performance Optimization Patterns

### Job Batching Strategy

```ruby
class BatchedResourceUpdateJob < ApplicationJob
  queue_as :resource_processing
  
  def perform(village_ids = nil, batch_size: 100)
    scope = village_ids ? Village.where(id: village_ids) : Village.active
    
    scope.find_in_batches(batch_size: batch_size) do |village_batch|
      process_village_batch(village_batch)
    end
  end
  
  private
  
  def process_village_batch(villages)
    # Pre-load associations to avoid N+1 queries
    villages = villages.includes(:buildings, :resources, :village_buildings)
    
    # Process villages in parallel using threads
    threads = villages.map do |village|
      Thread.new { process_single_village(village) }
    end
    
    # Wait for all threads to complete
    threads.each(&:join)
  end
  
  def process_single_village(village)
    # Individual village processing
    village.update_resources_from_buildings
    village.process_population_changes
    village.handle_scheduled_events
  rescue => error
    Rails.logger.error "Failed to process village #{village.id}: #{error.message}"
    ErrorTracker.report(error, village_id: village.id)
  end
end
```

### Memory-Efficient Processing

```ruby
class MemoryEfficientJob < ApplicationJob
  def perform(large_dataset_id)
    dataset = LargeDataset.find(large_dataset_id)
    
    # Process in chunks to manage memory usage
    dataset.items.find_each(batch_size: 1000) do |item|
      process_item(item)
      
      # Force garbage collection periodically
      GC.start if should_run_gc?
    end
  end
  
  private
  
  def process_item(item)
    # Process individual item
    # Avoid creating large temporary objects
    result = perform_calculation(item)
    store_result(item.id, result)
    
    # Clear any large temporary variables
    result = nil
  end
  
  def should_run_gc?
    # Run GC every 1000 processed items
    (@processed_count ||= 0) += 1
    @processed_count % 1000 == 0
  end
  
  def perform_calculation(item)
    # Memory-efficient calculation logic
    # Use streaming or iterative approaches instead of loading everything
  end
  
  def store_result(item_id, result)
    # Store result without keeping reference
    ResultStorage.create!(item_id: item_id, data: result)
  end
end
```

### Job Queue Optimization

```ruby
class PriorityAwareJob < ApplicationJob
  # Use different queues based on priority
  def self.enqueue_with_priority(priority, *args)
    queue_name = case priority
                 when :critical then :critical_queue
                 when :high then :high_priority_queue
                 when :normal then :default
                 when :low then :low_priority_queue
                 else :default
                 end
    
    set(queue: queue_name).perform_later(*args)
  end
  
  def perform(task_type, priority, *args)
    # Add priority context to logging
    Rails.logger.tagged("priority:#{priority}", "task:#{task_type}") do
      execute_task(task_type, *args)
    end
  end
  
  private
  
  def execute_task(task_type, *args)
    case task_type
    when 'user_notification'
      # High priority - user is waiting
      send_immediate_notification(*args)
    when 'data_backup'
      # Low priority - can be delayed
      perform_backup(*args)
    when 'report_generation'
      # Medium priority
      generate_report(*args)
    end
  end
end

# Usage
PriorityAwareJob.enqueue_with_priority(:critical, 'user_notification', user_id, message)
PriorityAwareJob.enqueue_with_priority(:low, 'data_backup', backup_type)
```

## Job Monitoring and Observability

### Job Performance Tracking

```ruby
class InstrumentedJob < ApplicationJob
  around_perform do |job, block|
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    memory_before = get_memory_usage
    
    begin
      result = block.call
      record_job_success(start_time, memory_before)
      result
    rescue => error
      record_job_failure(start_time, memory_before, error)
      raise
    end
  end
  
  private
  
  def record_job_success(start_time, memory_before)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    memory_after = get_memory_usage
    memory_delta = memory_after - memory_before
    
    JobMetrics.create!(
      job_class: self.class.name,
      job_id: job_id,
      status: 'success',
      duration: duration,
      memory_usage: memory_delta,
      arguments: arguments.to_s[0..255] # Truncate for storage
    )
    
    # Send metrics to monitoring system
    MetricsCollector.record('job.duration', duration, tags: {
      job_class: self.class.name,
      status: 'success'
    })
  end
  
  def record_job_failure(start_time, memory_before, error)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    
    JobMetrics.create!(
      job_class: self.class.name,
      job_id: job_id,
      status: 'failure',
      duration: duration,
      error_class: error.class.name,
      error_message: error.message[0..255]
    )
    
    MetricsCollector.record('job.duration', duration, tags: {
      job_class: self.class.name,
      status: 'failure',
      error_class: error.class.name
    })
  end
  
  def get_memory_usage
    # Platform-specific memory usage calculation
    case RUBY_PLATFORM
    when /linux/
      `ps -o rss= -p #{Process.pid}`.to_i * 1024 # Convert KB to bytes
    when /darwin/
      `ps -o rss= -p #{Process.pid}`.to_i * 1024
    else
      0 # Fallback for unsupported platforms
    end
  end
end
```

These advanced patterns provide the foundation for building robust, scalable background job systems that can handle complex workflows, maintain data consistency, and provide excellent observability in production environments.
