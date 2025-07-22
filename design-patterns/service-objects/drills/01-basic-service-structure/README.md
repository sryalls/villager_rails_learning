# Drill 1: Basic Service Object Structure

## Learning Goals

- Understand the fundamental structure of service objects
- Learn to include and use the `ServiceCallable` concern
- Practice returning proper result objects with success/failure status
- Implement error handling and logging in services

## Problem Description

Create a village creation service that initializes a new village with starting resources and buildings. This service should follow the basic service object pattern and handle errors gracefully.

## Requirements

- Include the `ServiceCallable` concern for consistent interface
- Return a result object with success/failure status  
- Handle errors gracefully with proper error messages
- Include appropriate logging for debugging
- Create initial resources (wood: 100, stone: 50, food: 25)
- Create a starting building (town hall)

## Files to Work With

- **`creation_service.rb`** - Main service file (edit this)
- **`creation_service_spec.rb`** - Test file (do not edit)

## TDD Workflow

1. Run the tests: `bundle exec rspec drills/01-basic-service-structure/creation_service_spec.rb`
2. See failing tests
3. Implement code in `creation_service.rb` to make tests pass
4. Repeat until all tests are green

## Key Concepts Practiced

- Service object structure and organization
- `ServiceCallable` concern usage
- `ServiceResult.success` and `ServiceResult.failure`
- Database transactions for data consistency
- Exception handling with `ActiveRecord::RecordInvalid`

## Related Documentation

- [Service Objects Main Documentation](../../README.md)
- [Advanced Patterns](../../advanced-patterns.md)
- [Implementation Examples](../../implementation-examples.md)

## Next Steps

After completing this drill, move on to Drill 2 to learn about service object concerns and code reuse patterns.
