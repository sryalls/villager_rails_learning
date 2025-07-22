# Drill 5: Distributed Job Coordination

## Exercise: Build Cross-Instance Job Coordination

**Goal:** Create jobs that coordinate across multiple application instances using Redis for distributed locking and state management.

## Learning Objectives

After completing this drill, you will understand:

- Distributed locking patterns to prevent duplicate execution
- Leader election algorithms for singleton jobs
- Cross-instance communication and coordination strategies
- Graceful handling of instance failures and failover
- Redis-based coordination mechanisms
- Building fault-tolerant distributed systems

## Requirements

- Distributed locking to prevent duplicate execution
- Leader election for singleton jobs
- Cross-instance communication and coordination
- Graceful handling of instance failures

## Workflow

1. **Understand the Problem**: Review distributed systems challenges and coordination patterns
2. **Run the Tests**: `bundle exec rspec drills/05-distributed-job-coordination/distributed_coordination_spec.rb`
3. **Implement**: Make tests pass by implementing distributed coordination mechanisms
4. **Test Scenarios**: Verify behavior under various failure conditions

## Key Concepts

- **Distributed Locking**: Preventing race conditions across multiple processes
- **Leader Election**: Ensuring only one instance performs singleton operations
- **Fault Tolerance**: Handling instance failures and network partitions gracefully
- **State Coordination**: Synchronizing state across distributed instances
- **Redis Coordination**: Using Redis primitives for distributed coordination

## Files

- `README.md` - This file
- `distributed_coordinator.rb` - Core coordination utilities
- `singleton_game_loop_job.rb` - Singleton job implementation
- `distributed_batch_job.rb` - Cross-instance batch processing
- `distributed_batch.rb` - Distributed batch state management
- `distributed_coordination_concern.rb` - Reusable coordination concern
- `create_distributed_batches.rb` - Migration for distributed batches
- `distributed_coordination_spec.rb` - Tests to make pass

## Links

- [Redis Distributed Locking](https://redis.io/docs/manual/patterns/distributed-locks/)
- [Leader Election Patterns](https://en.wikipedia.org/wiki/Leader_election)
- [Distributed Systems Concepts](https://www.allthingsdistributed.com/)
