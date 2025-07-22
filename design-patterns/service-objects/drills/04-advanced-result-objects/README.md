# Drill 4: Advanced Result Objects with OpenStruct

## Learning Goals

- Build rich result objects with comprehensive data structures
- Implement method chaining with success/failure handlers
- Learn to handle partial successes and failures
- Create meaningful result summaries and reports
- Practice state tracking across complex operations

## Problem Description

Create a comprehensive game state update service that processes multiple village systems simultaneously and returns rich result objects with detailed metrics, state changes, and handling capabilities.

## Requirements

### Advanced Result Object Features
- Use OpenStruct for flexible data structures
- Support method chaining with `on_success`, `on_failure`, `on_partial_success`
- Include detailed metrics for all operations
- Provide human-readable summaries
- Track partial successes/failures

### Game State Updates
- Process building production for all buildings
- Handle population changes and growth
- Process random game events (weather, merchants, etc.)
- Calculate overall village performance score
- Track individual operation successes/failures

## Files to Work With

- **`state_update_service.rb`** - Main game state service (edit this)
- **`game_state_result.rb`** - Advanced result object class (edit this)
- **`state_update_service_spec.rb`** - Test file (do not edit)

## TDD Workflow

1. Run the tests: `bundle exec rspec drills/04-advanced-result-objects/state_update_service_spec.rb`
2. See failing tests
3. Implement service and result class to make tests pass
4. Repeat until all tests are green

## Key Concepts Practiced

- OpenStruct for dynamic result objects
- Method chaining and fluent interfaces
- Partial success/failure handling
- Comprehensive state tracking
- Rich data structures and metrics
- Human-readable reporting

## Related Documentation

- [Service Objects Advanced Patterns](../../advanced-patterns.md#rich-result-objects)
- [State Management](../../advanced-patterns.md#state-management)
- [Result Object Design](../../advanced-patterns.md#result-object-patterns)

## Next Steps

After completing this drill, move on to Drill 5 to learn about idempotent services and distributed processing patterns.
