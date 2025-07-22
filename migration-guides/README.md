# Migration Guides

Step-by-step guides for major upgrades and migrations in the Villager Rails project.

## Current Migrations

### [Propshaft 1.1.0 → Pure Propshaft Pipeline](propshaft-migration.md)
**Status**: Planned  
**Priority**: High  
**Complexity**: Medium  

Migrate from the current Propshaft + Sprockets hybrid approach to a pure Propshaft asset pipeline.

### [Rails 7 → Rails 8 Upgrade](rails-8-upgrade.md)
**Status**: Completed  
**Priority**: High  
**Complexity**: Medium  

Complete guide to upgrading from Rails 7 to Rails 8, including Propshaft adoption and new features.

### [PostgreSQL Optimization](postgresql-optimization.md)
**Status**: Planned  
**Priority**: Medium  
**Complexity**: Low  

Database performance improvements and index optimization for better game performance.

## Migration Planning Template

When planning a migration, use this template:

### Migration: [Technology/Feature Name]

#### Overview
- **Current State**: Brief description of current implementation
- **Target State**: Description of desired end state
- **Business Justification**: Why this migration is necessary
- **Risk Assessment**: Potential issues and mitigation strategies

#### Prerequisites
- [ ] Prerequisite 1
- [ ] Prerequisite 2
- [ ] Prerequisite 3

#### Migration Steps
1. **Preparation Phase**
   - [ ] Step 1
   - [ ] Step 2

2. **Implementation Phase**
   - [ ] Step 1
   - [ ] Step 2

3. **Validation Phase**
   - [ ] Step 1
   - [ ] Step 2

4. **Cleanup Phase**
   - [ ] Step 1
   - [ ] Step 2

#### Testing Strategy
- [ ] Unit tests updated
- [ ] System tests verified
- [ ] Performance benchmarks
- [ ] Rollback plan tested

#### Rollback Plan
- Emergency rollback procedure
- Data recovery steps
- Communication plan

#### Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Related Documentation

- [Architecture Overview](../architecture/README.md)
- [Troubleshooting Guide](../troubleshooting/README.md)
- [Learning Resources](../learning-resources/README.md)
