# Drill 5: Idempotent Background Job Services

## Learning Goals

- Implement database-level idempotency using unique constraints
- Handle race conditions in distributed systems
- Build distributed locking with Redis
- Create time-window based operations
- Practice comprehensive logging and monitoring

## Problem Description

Build an idempotent resource collection service suitable for background job execution. The service must safely handle multiple executions without side effects, support distributed processing, and maintain operation records for auditing.

## Requirements

### Idempotency Features
- Generate unique idempotency keys based on time windows
- Use database constraints to prevent duplicate operations
- Handle race conditions gracefully
- Support distributed locking with Redis

### Resource Collection Logic
- Collect resources from all village buildings
- Apply time-based bonuses and multipliers
- Record all collection operations for auditing
- Support different collection types (scheduled, manual, event-based)

### Error Handling
- Handle missing villages gracefully
- Manage database constraint violations
- Provide meaningful error messages
- Log all operations comprehensively

## Files to Work With

- **`collection_service.rb`** - Main idempotent service (edit this)
- **`resource_collection.rb`** - Model for tracking operations (edit this)
- **`create_resource_collections.rb`** - Database migration (edit this)
- **`collection_service_spec.rb`** - Test file (do not edit)

## TDD Workflow

1. Run the tests: `bundle exec rspec drills/05-idempotent-services/collection_service_spec.rb`
2. See failing tests
3. Implement service, model, and migration to make tests pass
4. Repeat until all tests are green

## Key Concepts Practiced

- Idempotency patterns and implementation
- Database constraint usage for concurrency control
- Distributed locking with Redis
- Time-window based operations
- Race condition handling
- Comprehensive error management
- Background job best practices

## Related Documentation

- [Service Objects Advanced Patterns](../../advanced-patterns.md#idempotent-services)
- [Background Jobs Integration](../../advanced-patterns.md#background-job-integration)
- [Distributed Processing](../../advanced-patterns.md#distributed-processing)

## Next Steps

After completing this drill, you'll have mastered the core service object patterns. Consider working on the progressive difficulty challenges to further enhance your skills.
