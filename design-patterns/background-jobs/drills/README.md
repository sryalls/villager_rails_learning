# Background Jobs Coding Drills

This directory contains structured coding drills for mastering background job patterns in Rails applications. Each drill focuses on specific concepts and builds upon previous knowledge.

## Drill Structure

Each drill follows the same TDD workflow pattern:

1. **Problem Description** - Clear explanation of the challenge and learning objectives
2. **Starter Code** - Skeletal implementation with TODO comments
3. **Test File** - Comprehensive tests that must pass (unaltered)
4. **Supporting Files** - Models, migrations, and utilities needed for the drill

## Available Drills

### [01 - Basic Idempotent Job](01-basic-idempotent-job/)
**Focus:** Database-level idempotency, concurrent execution safety, audit trails

Learn to build jobs that are safe to run multiple times without negative side effects, using database constraints and proper error handling.

### [02 - Smart Retry Strategy Job](02-smart-retry-strategy/)
**Focus:** Intelligent error handling, circuit breaker pattern, dead letter queues

Master different retry strategies for different error types, implement circuit breakers for external services, and handle permanent failures gracefully.

### [03 - Job Orchestration Workflow](03-job-orchestration-workflow/)
**Focus:** Multi-step workflows, state management, rollback capabilities

Build complex workflows that coordinate multiple jobs in sequence and parallel, with proper state persistence and failure recovery.

### [04 - Performance-Optimized Batch Processing](04-performance-optimized-batch/)
**Focus:** Memory management, parallel processing, progress tracking

Create high-performance batch jobs that efficiently process large datasets with memory optimization and thread safety.

### [05 - Distributed Job Coordination](05-distributed-job-coordination/)
**Focus:** Cross-instance coordination, leader election, distributed locking

Implement jobs that coordinate across multiple application instances using Redis for distributed state management and failure handling.

## Workflow

Each drill follows the Test-Driven Development (TDD) approach:

1. **Read** the drill README to understand the problem and learning objectives
2. **Run** the tests initially to see them fail
3. **Implement** the solution incrementally, making tests pass one by one
4. **Refactor** and optimize while keeping tests green
5. **Verify** all tests pass and understand the patterns used

## Prerequisites

- Basic understanding of Rails Active Job
- Familiarity with RSpec testing framework
- Understanding of Redis (for distributed coordination drill)
- Basic knowledge of concurrent programming concepts

## Practice Schedule

**Recommended Timeline:** 1 drill per week

- **Week 1:** Basic Idempotent Job
- **Week 2:** Smart Retry Strategy Job  
- **Week 3:** Job Orchestration Workflow
- **Week 4:** Performance-Optimized Batch Processing
- **Week 5:** Distributed Job Coordination

## Success Metrics

For each drill, aim for:
- ✅ All tests passing
- ✅ Code coverage > 90%
- ✅ Performance benchmarks met (where applicable)
- ✅ Error scenarios handled gracefully
- ✅ Clean, readable code with proper documentation

## Advanced Challenge

After completing all drills, try the **Event-Driven Job Architecture** challenge in the main [coding-drills.md](../coding-drills.md) file for an advanced distributed systems exercise.

## Links

- [Rails Active Job Guide](https://guides.rubyonrails.org/active_job_basics.html)
- [Sidekiq Documentation](https://github.com/mperham/sidekiq/wiki)
- [Background Job Best Practices](../references.md)
