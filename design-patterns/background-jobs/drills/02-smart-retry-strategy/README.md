# Drill 2: Smart Retry Strategy Job

## Exercise: Build a Job with Intelligent Error Handling

**Goal:** Create a job that handles different types of errors with appropriate retry strategies.

## Learning Objectives

After completing this drill, you will understand:

- How to implement different retry strategies for different error types
- Circuit breaker pattern for external API failures
- Dead letter queue management for permanent failures
- Comprehensive error logging and monitoring
- How to balance reliability with performance in background jobs

## Requirements

- Different retry strategies for different error types
- Circuit breaker pattern for external API failures  
- Dead letter queue for permanent failures
- Comprehensive error logging and monitoring

## Workflow

1. **Understand the Problem**: Review the starter code and test requirements
2. **Run the Tests**: `bundle exec rspec drills/02-smart-retry-strategy/smart_retry_job_spec.rb`
3. **Implement**: Make tests pass by implementing the missing functionality
4. **Verify**: Ensure all tests pass and error handling works correctly

## Key Concepts

- **Retry Strategies**: Different errors require different retry approaches
- **Circuit Breaker**: Prevents cascading failures in distributed systems
- **Dead Letter Queue**: Storage for permanently failed jobs
- **Error Classification**: Distinguishing between transient and permanent errors

## Files

- `README.md` - This file
- `smart_retry_job.rb` - Main job implementation
- `circuit_breaker_state.rb` - Circuit breaker state tracking
- `dead_letter_job.rb` - Dead letter queue model
- `create_circuit_breaker_states.rb` - Migration for circuit breaker
- `create_dead_letter_jobs.rb` - Migration for dead letter queue
- `smart_retry_job_spec.rb` - Tests to make pass

## Links

- [Sidekiq Retry Documentation](https://github.com/mperham/sidekiq/wiki/Error-Handling)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
- [Dead Letter Queue Pattern](https://en.wikipedia.org/wiki/Dead_letter_queue)
