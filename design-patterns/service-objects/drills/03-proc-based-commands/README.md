# Drill 3: Proc-based Command Pattern

## Learning Goals

- Implement flexible command systems using Ruby procs
- Build undo functionality for reversible operations
- Learn command composition and chaining
- Practice validation within command contexts
- Understand command history and state management

## Problem Description

Create a village command system that uses procs to define flexible, composable operations. Commands should support undo operations where possible and maintain a history of executed operations.

## Requirements

### Command System Features
- Define commands as reusable procs
- Support undo operations for reversible commands
- Maintain command execution history
- Validate commands before execution
- Handle command failures gracefully

### Supported Commands
- `add_building` - Add a building at specific coordinates
- `remove_building` - Remove a building by ID
- `upgrade_building` - Upgrade a building's level
- `add_resources` - Add resources to village
- `consume_resources` - Consume resources with validation

## Files to Work With

- **`command_service.rb`** - Main command system (edit this)
- **`command_service_spec.rb`** - Test file (do not edit)

## TDD Workflow

1. Run the tests: `bundle exec rspec drills/03-proc-based-commands/command_service_spec.rb`
2. See failing tests
3. Implement command system to make tests pass
4. Repeat until all tests are green

## Key Concepts Practiced

- Proc/lambda usage in Ruby
- Command pattern implementation
- Undo/redo functionality
- State management and history tracking
- Validation within command contexts
- Error handling in command execution

## Related Documentation

- [Service Objects Advanced Patterns](../../advanced-patterns.md#proc-based-command-pattern)
- [State Management Patterns](../../advanced-patterns.md#state-management)
- [Command Composition](../../advanced-patterns.md#command-composition)

## Next Steps

After completing this drill, move on to Drill 4 to learn about advanced result objects with rich data structures and method chaining.
