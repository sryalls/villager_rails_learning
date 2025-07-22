# Propshaft 1.2.0 Compatibility Issue

## Problem Summary

**Date**: December 2024  
**Severity**: Critical  
**Impact**: Asset pipeline broken, auto-refresh functionality disabled  

### Issue Description

A Dependabot PR upgraded Propshaft from 1.1.0 to 1.2.0, which broke the asset pipeline and disabled the auto-refresh functionality that's critical for the real-time village simulation game.

### Symptoms Observed

1. **Asset Compilation Failures**:
   - Rails asset precompilation errors
   - Missing CSS/JS files in development
   - Build failures in production

2. **Auto-Refresh Broken**:
   - Village resource updates not displaying in real-time
   - Turbo Stream connections not working
   - Background job outputs not reaching the UI

3. **Test Failures**:
   - System tests failing due to missing assets
   - Auto-refresh spec timing out
   - Resource stream endpoint tests failing

### Root Cause Analysis

The Propshaft 1.2.0 release removed the Sprockets compatibility layer that the project's current asset configuration depends on. Specifically:

- **sassc-rails** gem requires Sprockets compatibility
- **Existing asset manifests** use Sprockets-style directives
- **CSS compilation pipeline** relies on Sprockets preprocessors

### Investigation Process

1. **Branch Comparison**:
   ```bash
   # Compare working main branch vs failing PR branch
   git diff main dependabot/bundler/propshaft-1.2.0
   ```

2. **Test Validation**:
   ```bash
   # Main branch tests (passing)
   rspec spec/system/village_auto_refresh_spec.rb
   rspec spec/requests/village_resources_spec.rb
   
   # PR branch tests (failing)
   git checkout dependabot/bundler/propshaft-1.2.0
   rspec spec/system/village_auto_refresh_spec.rb # FAILED
   ```

3. **Asset Pipeline Testing**:
   ```bash
   # Main branch (working)
   rails assets:precompile # SUCCESS
   
   # PR branch (broken)
   rails assets:precompile # FAILED
   ```

### Solution Implemented

**Immediate Fix**: Pin Propshaft to version 1.1.0

```ruby
# Gemfile
gem 'propshaft', '~> 1.1.0'  # Pin to working version
# TODO: Plan migration to pure Propshaft pipeline
# See: https://github.com/your-org/villager_rails/issues/XXX
```

**Verification Steps**:
```bash
bundle update propshaft
rails assets:precompile
rspec spec/system/village_auto_refresh_spec.rb
rails server # Test auto-refresh manually
```

### Long-Term Migration Plan

A comprehensive migration to a pure Propshaft pipeline is needed. Key steps:

1. **Remove Sprockets Dependencies**:
   - Replace sassc-rails with pure CSS compilation
   - Update asset manifests to Propshaft format
   - Remove Sprockets-specific directives

2. **Asset Pipeline Modernization**:
   - Implement CSS bundling without Sprockets
   - Update JavaScript asset handling
   - Ensure development auto-refresh compatibility

3. **Testing Strategy**:
   - Validate all asset types compile correctly
   - Ensure auto-refresh functionality maintained
   - Comprehensive system test coverage

4. **Deployment Validation**:
   - Test asset serving in production
   - Verify CDN compatibility
   - Performance impact assessment

### Lessons Learned

1. **Asset Pipeline Dependencies**: Modern Rails asset pipelines have complex interdependencies that require careful upgrade planning.

2. **Critical Feature Testing**: Auto-refresh is a core game feature that needs robust test coverage during infrastructure changes.

3. **Gradual Migration Strategy**: Major asset pipeline changes should be planned incrementally rather than handled through automated dependency updates.

4. **Documentation Importance**: Asset pipeline configurations need clear documentation of their dependencies and upgrade paths.

### Related Issues

- **GitHub Issue**: [Plan migration to pure Propshaft pipeline](#)
- **Documentation**: [Asset Pipeline Architecture](../architecture/asset-pipeline.md)
- **Migration Guide**: [Propshaft Migration Plan](../migration-guides/propshaft-migration.md)

### Prevention Strategies

1. **Dependency Management**:
   - Pin critical dependencies that affect core functionality
   - Use automated testing for asset pipeline changes
   - Document dependency relationships clearly

2. **CI/CD Improvements**:
   - Add asset compilation checks to CI pipeline
   - Include system tests in automated testing
   - Test deployment scenarios with asset changes

3. **Monitoring**:
   - Add monitoring for auto-refresh functionality
   - Track asset loading performance
   - Alert on asset compilation failures

---

*This issue demonstrates the importance of understanding dependency relationships in modern Rails applications and the need for comprehensive testing of critical features during infrastructure upgrades.*
