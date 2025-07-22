# Background Jobs Implementation Examples

This document provides practical code examples and implementation patterns for background jobs in Rails applications, with specific examples from the Villager Rails project.

## Basic Job Structure

### Simple Job Example
```ruby
class WelcomeEmailJob < ApplicationJob
  queue_as :default
  
  def perform(user_id)
    user = User.find(user_id)
    UserMailer.welcome(user).deliver_now
  end
end
```

### Job with Service Object Integration
```ruby
class ProcessVillageUpdateJob < ApplicationJob
  queue_as :village_processing
  
  def perform(village_id)
    village = Village.find(village_id)
    VillageUpdateService.new(village).call
  rescue ActiveRecord::RecordNotFound
    # Village was deleted, nothing to do
    Rails.logger.info "Village #{village_id} not found, skipping update"
  end
end
```

## Villager Rails Job Examples

### Village Loop Job
```ruby
class VillageLoopJob < ApplicationJob
  queue_as :default

  def perform(village_id)
    village = Village.find(village_id)
    
    # Delegate to service object for business logic
    VillageLoopService.new(village).call
    
    # Schedule next iteration
    VillageLoopJob.set(wait: 30.seconds).perform_later(village_id)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.info "Village #{village_id} deleted, stopping loop"
  end
end
```

### Resource Production Job
```ruby
class ProduceResourcesFromBuildingJob < ApplicationJob
  queue_as :resource_generation
  
  def perform(village_building_id)
    village_building = VillageBuilding.find(village_building_id)
    
    # Use service object for complex business logic
    result = ProduceResourcesFromBuildingService.new(village_building).call
    
    if result.success?
      # Broadcast updates via Turbo Stream
      broadcast_resource_update(village_building.village, result.resources)
    end
  rescue ActiveRecord::RecordNotFound
    # Building was destroyed, nothing to produce
  end
  
  private
  
  def broadcast_resource_update(village, resources)
    village.broadcast_replace_to(
      "village_#{village.id}_resources",
      target: "village_resources",
      partial: "villages/resources",
      locals: { village: village, resources: resources }
    )
  end
end
```

### Play Loop Job (Recurring)
```ruby
class PlayLoopJob < ApplicationJob
  queue_as :game_loop
  
  def perform
    # Process all active villages
    Village.active.find_each do |village|
      VillageLoopJob.perform_later(village.id)
    end
    
    # Clean up old data
    cleanup_expired_sessions
    
    # Schedule next game loop
    PlayLoopJob.set(wait: 1.minute).perform_later
  end
  
  private
  
  def cleanup_expired_sessions
    # Cleanup logic here
  end
end
```

## Error Handling Patterns

### Retry Strategies
```ruby
class ReliableJob < ApplicationJob
  # Exponential backoff with jitter
  retry_on StandardError, 
           wait: :exponentially_longer, 
           attempts: 5,
           jitter: 0.3
  
  # Don't retry on permanent failures
  discard_on ArgumentError, ActiveRecord::RecordNotFound
  
  # Custom retry logic
  retry_on TimeoutError, wait: 30.seconds, attempts: 3
  
  def perform(resource_id)
    resource = Resource.find(resource_id)
    process_resource(resource)
  end
end
```

### Custom Error Handling
```ruby
class MonitoredJob < ApplicationJob
  rescue_from StandardError do |exception|
    # Log the error
    Rails.logger.error "Job failed: #{exception.message}"
    
    # Report to error tracking service
    ErrorTracker.report(exception, job_data: {
      job_class: self.class.name,
      arguments: arguments
    })
    
    # Re-raise to trigger retry logic
    raise exception
  end
  
  def perform
    # Job logic here
  end
end
```

## Scheduling Patterns

### Delayed Execution
```ruby
# Schedule for specific time
WelcomeEmailJob.set(wait_until: 1.hour.from_now).perform_later(user.id)

# Schedule with delay
ReportGenerationJob.set(wait: 5.minutes).perform_later(report_id)

# Schedule at specific time
DailyReportJob.set(wait_until: Date.tomorrow.beginning_of_day).perform_later
```

### Recurring Jobs
```ruby
class RecurringMaintenanceJob < ApplicationJob
  def perform
    # Do maintenance work
    perform_cleanup
    
    # Schedule next run
    self.class.set(wait: 1.day).perform_later
  end
  
  private
  
  def perform_cleanup
    # Cleanup logic
  end
end

# Start the recurring job
RecurringMaintenanceJob.perform_later
```

### Cron-like Scheduling
```ruby
# Using whenever gem or similar
class DailyStatsJob < ApplicationJob
  def perform
    # Calculate daily statistics
    generate_daily_reports
    update_leaderboards
  end
end

# In schedule.rb (whenever gem)
every 1.day, at: '3:00 am' do
  runner "DailyStatsJob.perform_later"
end
```

## Queue Management

### Queue Prioritization
```ruby
class ApplicationJob < ActiveJob::Base
  # Default queue
  queue_as :default
end

class CriticalJob < ApplicationJob
  queue_as :critical
end

class LowPriorityJob < ApplicationJob
  queue_as :low_priority
end

class GameLoopJob < ApplicationJob
  queue_as :game_processing
end
```

### Dynamic Queue Assignment
```ruby
class FlexibleJob < ApplicationJob
  def perform(priority_level)
    queue_name = case priority_level
                 when 'urgent' then :critical
                 when 'normal' then :default
                 else :low_priority
                 end
    
    self.class.set(queue: queue_name).perform_later
  end
end
```

## Performance Patterns

### Batch Processing
```ruby
class BatchProcessorJob < ApplicationJob
  def perform(batch_id)
    batch = ProcessingBatch.find(batch_id)
    
    batch.items.find_in_batches(batch_size: 100) do |item_batch|
      item_batch.each do |item|
        process_item(item)
      end
    end
  end
  
  private
  
  def process_item(item)
    # Process individual item
  end
end
```

### Job Splitting
```ruby
class LargeDatasetJob < ApplicationJob
  def perform(dataset_id, offset = 0, limit = 1000)
    dataset = Dataset.find(dataset_id)
    items = dataset.items.offset(offset).limit(limit)
    
    items.each { |item| process_item(item) }
    
    # If there are more items, schedule next batch
    if items.count == limit
      self.class.perform_later(dataset_id, offset + limit, limit)
    end
  end
end
```

## Testing Patterns

### Testing Job Execution
```ruby
RSpec.describe VillageLoopJob, type: :job do
  let(:village) { create(:village) }
  
  describe '#perform' do
    it 'processes village update' do
      expect(VillageLoopService).to receive(:new).with(village).and_call_original
      
      described_class.perform_now(village.id)
    end
    
    it 'schedules next iteration' do
      expect {
        described_class.perform_now(village.id)
      }.to have_enqueued_job(described_class).with(village.id).at(30.seconds.from_now)
    end
    
    it 'handles missing village gracefully' do
      expect {
        described_class.perform_now(-1)
      }.not_to raise_error
    end
  end
end
```

### Testing with ActiveJob::TestHelper
```ruby
RSpec.describe 'Village processing', type: :system do
  include ActiveJob::TestHelper
  
  it 'processes village updates in background' do
    village = create(:village)
    
    expect {
      village.start_processing!
    }.to have_enqueued_job(VillageLoopJob).with(village.id)
    
    perform_enqueued_jobs do
      # Verify the job was processed
      expect(village.reload.last_processed_at).to be_present
    end
  end
end
```

### Mock Job Processing
```ruby
RSpec.describe VillagesController, type: :request do
  before do
    # Disable actual job processing for faster tests
    ActiveJob::Base.queue_adapter = :test
  end
  
  it 'enqueues village processing job' do
    village = create(:village)
    
    expect {
      post village_start_path(village)
    }.to have_enqueued_job(VillageLoopJob)
  end
end
```

## Monitoring and Debugging

### Job Instrumentation
```ruby
class InstrumentedJob < ApplicationJob
  around_perform do |job, block|
    start_time = Time.current
    
    begin
      block.call
      record_success(Time.current - start_time)
    rescue => error
      record_failure(error, Time.current - start_time)
      raise
    end
  end
  
  private
  
  def record_success(duration)
    Rails.logger.info "Job #{self.class.name} completed in #{duration}s"
  end
  
  def record_failure(error, duration)
    Rails.logger.error "Job #{self.class.name} failed after #{duration}s: #{error.message}"
  end
end
```

### Job Status Tracking
```ruby
class TrackableJob < ApplicationJob
  def perform(task_id)
    task = Task.find(task_id)
    task.update!(status: 'processing')
    
    begin
      process_task(task)
      task.update!(status: 'completed')
    rescue => error
      task.update!(status: 'failed', error_message: error.message)
      raise
    end
  end
end
```

These examples demonstrate practical implementation patterns for background jobs in Rails applications, emphasizing reliability, testability, and integration with the broader application architecture.
