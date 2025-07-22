# Drill 3: Job Orchestration Workflow

## Exercise: Build a Multi-Step Workflow System

**Goal:** Create a workflow system that orchestrates multiple jobs in sequence with proper state management.

## Learning Objectives

After completing this drill, you will understand:

- How to design and implement multi-step workflows with background jobs
- Sequential vs parallel job execution patterns
- Workflow state persistence and recovery mechanisms
- Conditional step execution based on previous results
- Rollback capability for failed workflows
- Error handling and recovery in complex workflows

## Requirements

- Support for sequential and parallel job execution
- Workflow state persistence and recovery
- Conditional step execution based on previous results
- Rollback capability for failed workflows

## Workflow

1. **Understand the Problem**: Review the workflow definition structure and orchestration logic
2. **Run the Tests**: `bundle exec rspec drills/03-job-orchestration-workflow/workflow_orchestrator_job_spec.rb`
3. **Implement**: Make tests pass by implementing the workflow orchestration system
4. **Verify**: Ensure all workflow scenarios work correctly including failure recovery

## Key Concepts

- **Workflow Definition**: Declarative definition of workflow steps and dependencies
- **State Management**: Persisting workflow state for recovery and monitoring
- **Parallel Execution**: Running independent steps concurrently for better performance
- **Rollback Strategy**: Undoing completed steps when workflow fails
- **Step Prerequisites**: Conditional execution based on previous step results

## Files

- `README.md` - This file
- `game_workflow.rb` - Workflow state management model
- `workflow_orchestrator_job.rb` - Main orchestration job
- `workflow_step_jobs.rb` - Individual workflow step implementations
- `workflow_service.rb` - Service for starting and managing workflows
- `create_game_workflows.rb` - Migration for workflow state
- `workflow_orchestrator_job_spec.rb` - Tests to make pass

## Links

- [Workflow Patterns](https://www.workflowpatterns.com/)
- [Saga Pattern](https://microservices.io/patterns/data/saga.html)
- [Rails Job Chaining](https://guides.rubyonrails.org/active_job_basics.html)
