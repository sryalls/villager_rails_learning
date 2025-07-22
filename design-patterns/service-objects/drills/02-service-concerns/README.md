# Drill 2: Service Object with Concerns

## Learning Goals

- Create reusable concerns for service objects
- Implement cross-cutting functionality (tracking, caching)
- Learn to compose concerns for enhanced functionality
- Understand concern hooks and callbacks
- Practice caching strategies in service objects

## Problem Description

Build two reusable concerns (`Trackable` and `Cacheable`) that can be included in any service object to add tracking and caching functionality. Then apply these concerns to a resource production service.

## Requirements

### Trackable Concern
- Log service execution start and completion
- Include execution time and result status
- Use Rails logger with appropriate log levels

### Cacheable Concern  
- Cache service results using Rails cache
- Generate cache keys from service class and arguments
- Support configurable expiration times
- Handle cache misses gracefully

### Production Service
- Include both concerns
- Implement resource production logic
- Use caching to avoid repeated calculations

## Files to Work With

- **`trackable.rb`** - Trackable concern (edit this)
- **`cacheable.rb`** - Cacheable concern (edit this)
- **`production_service.rb`** - Main service using concerns (edit this)
- **`production_service_spec.rb`** - Test file (do not edit)

## TDD Workflow

1. Run the tests: `bundle exec rspec drills/02-service-concerns/production_service_spec.rb`
2. See failing tests
3. Implement concerns and service to make tests pass
4. Repeat until all tests are green

## Key Concepts Practiced

- ActiveSupport::Concern usage and best practices
- Service object composition with concerns
- Caching strategies and cache key generation
- Logging and instrumentation in services
- Callback hooks in concerns

## Related Documentation

- [Service Objects Advanced Patterns](../../advanced-patterns.md#concern-based-composition)
- [Caching Strategies](../../advanced-patterns.md#caching-and-memoization)
- [Instrumentation Patterns](../../advanced-patterns.md#instrumentation-and-monitoring)

## Next Steps

After completing this drill, move on to Drill 3 to learn about proc-based command patterns and flexible service architectures.
