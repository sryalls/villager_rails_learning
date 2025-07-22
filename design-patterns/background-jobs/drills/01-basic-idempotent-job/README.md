# Drill 1: Basic Idempotent Job

## Learning Goals

- Implement database-level idempotency using unique constraints
- Handle concurrent job execution gracefully  
- Build audit trails for background operations
- Practice error handling in background jobs
- Use Sidekiq for asynchronous job processing

## Problem Description

Create an idempotent resource collection job that collects resources from village buildings. The job must be safe to run multiple times within the same time window without duplicating resource collection or creating inconsistent state.

## Requirements

### Idempotency Features
- Use database-level idempotency with unique constraints
- Handle concurrent execution gracefully using database constraints
- Track collection operations for audit and debugging purposes
- Group collections into 1-hour time windows

### Resource Collection Logic
- Collect resources from all village buildings
- Update village resource totals atomically
- Calculate total value of collected resources
- Broadcast real-time updates via Turbo Streams

### Error Handling
- Handle deleted villages gracefully
- Manage database constraint violations
- Provide meaningful error messages
- Include comprehensive logging

## Files to Work With

- **`create_resource_collections.rb`** - Database migration (edit this)
- **`resource_collection.rb`** - Model for tracking collections (edit this)
- **`idempotent_resource_collection_job.rb`** - Main job implementation (edit this)
- **`idempotent_resource_collection_job_spec.rb`** - Test file (do not edit)

## TDD Workflow

1. Run the tests: `bundle exec rspec drills/01-basic-idempotent-job/idempotent_resource_collection_job_spec.rb`
2. See failing tests
3. Implement migration, model, and job to make tests pass
4. Repeat until all tests are green

## Key Concepts Practiced

- Idempotency patterns in background jobs
- Database constraint usage for concurrency control
- Time-window based operations
- Active Job best practices
- Turbo Stream broadcasting
- Comprehensive error handling

## Related Documentation

- [Background Jobs Main Documentation](../../README.md)
- [Advanced Patterns](../../advanced-patterns.md)
- [Idempotency Patterns](../../advanced-patterns.md#idempotency-patterns)

## Next Steps

After completing this drill, move on to Drill 2 to learn about intelligent retry strategies and circuit breaker patterns.
