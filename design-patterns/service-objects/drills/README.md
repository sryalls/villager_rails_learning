# Service Objects Coding Drills Overview

This directory contains hands-on coding exercises designed to help you master service object patterns and advanced techniques. Each drill is organized in its own folder with a complete TDD workflow.

## Drill Structure

Each drill folder contains:

- **README.md** - Problem description, learning goals, and instructions
- **Starter code files** - Files to edit during the drill
- **Test files** - Complete test suites (do not edit these)
- **Supporting files** - Models, migrations, and other dependencies

## Available Drills

### [Drill 1: Basic Service Object Structure](./01-basic-service-structure/)
**Learning Focus:** Fundamental service object patterns, ServiceCallable concern, result objects
**Files:** `creation_service.rb`, `creation_service_spec.rb`

Create a village creation service that demonstrates the basic service object structure with proper error handling and logging.

### [Drill 2: Service Object with Concerns](./02-service-concerns/)
**Learning Focus:** Reusable concerns, cross-cutting functionality, composition patterns
**Files:** `trackable.rb`, `cacheable.rb`, `production_service.rb`, `production_service_spec.rb`

Build `Trackable` and `Cacheable` concerns and apply them to a resource production service.

### [Drill 3: Proc-based Command Pattern](./03-proc-based-commands/)
**Learning Focus:** Flexible command systems, undo functionality, proc usage
**Files:** `command_service.rb`, `command_service_spec.rb`

Implement a village command system using procs with undo operations and command history.

### [Drill 4: Advanced Result Objects](./04-advanced-result-objects/)
**Learning Focus:** Rich data structures, method chaining, partial successes
**Files:** `state_update_service.rb`, `game_state_result.rb`, `state_update_service_spec.rb`

Create comprehensive result objects with OpenStruct and chainable operations for complex game state updates.

### [Drill 5: Idempotent Services](./05-idempotent-services/)
**Learning Focus:** Distributed processing, race conditions, database constraints
**Files:** `collection_service.rb`, `resource_collection.rb`, `create_resource_collections.rb`, `collection_service_spec.rb`

Build an idempotent resource collection service suitable for background job execution.

## TDD Workflow

Each drill follows the same TDD approach:

1. **Read the README** - Understand the problem and requirements
2. **Run the tests** - See what needs to be implemented
   ```bash
   bundle exec rspec drills/01-basic-service-structure/creation_service_spec.rb
   ```
3. **Implement incrementally** - Make one test pass at a time
4. **Refactor** - Improve code quality while keeping tests green
5. **Move to next test** - Repeat until all tests pass

## Running Tests

### Individual Drill
```bash
# Run tests for a specific drill
bundle exec rspec drills/01-basic-service-structure/
bundle exec rspec drills/02-service-concerns/
```

### Specific Test Groups
```bash
# Run specific test groups within a drill
bundle exec rspec drills/02-service-concerns/production_service_spec.rb -e "tracking"
bundle exec rspec drills/03-proc-based-commands/command_service_spec.rb -e "undo"
```

### All Drills
```bash
# Run all drill tests
bundle exec rspec drills/
```

## Progressive Difficulty

The drills are designed to build upon each other:

- **Drills 1-2:** Foundation patterns and basic composition
- **Drills 3-4:** Advanced patterns and complex data handling  
- **Drill 5:** Production-ready patterns for distributed systems

## Tips for Success

1. **Start Simple** - Get basic functionality working before adding complexity
2. **Read Tests Carefully** - Tests define the exact requirements and expected behavior
3. **One Test at a Time** - Focus on making one test pass before moving to the next
4. **Use the Documentation** - Each README links to relevant advanced patterns
5. **Experiment** - Try different approaches and see how they affect the tests

## Practice Schedule

**Week 1:** Drills 1-2 (Foundation patterns)
**Week 2:** Drill 3 (Command patterns)  
**Week 3:** Drill 4 (Advanced results)
**Week 4:** Drill 5 (Production patterns)
**Week 5+:** Apply patterns to real Villager Rails features

## Related Documentation

- [Service Objects Main Documentation](../README.md)
- [Advanced Patterns](../advanced-patterns.md)
- [Implementation Examples](../implementation-examples.md)

## Getting Help

If you get stuck:

1. Check the README for hints and documentation links
2. Look at the test descriptions for clues about expected behavior
3. Review the related documentation sections
4. Start with the simplest implementation that makes tests pass

Remember: The goal is to learn the patterns, not to write perfect code on the first try!
