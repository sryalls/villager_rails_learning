# Propshaft Migration Plan

## Overview

Migrate from the current Propshaft 1.1.0 + Sprockets hybrid approach to a pure Propshaft asset pipeline, eliminating compatibility issues and preparing for future Rails upgrades.

**Current State**: Propshaft 1.1.0 with Sprockets compatibility layer  
**Target State**: Pure Propshaft pipeline without Sprockets dependencies  
**Business Justification**: Eliminate compatibility issues, improve performance, future-proof asset pipeline  
**Risk Assessment**: Medium risk due to critical auto-refresh functionality dependency  

## Prerequisites

- [ ] Current system fully functional with Propshaft 1.1.0
- [ ] Comprehensive test coverage for asset-dependent features
- [ ] Development environment setup with asset compilation
- [ ] Staging environment available for testing
- [ ] Rollback plan documented and tested

## Migration Steps

### Phase 1: Preparation (1-2 days)

#### 1.1 Asset Audit
- [ ] Catalog all current asset files and their dependencies
- [ ] Document Sprockets-specific directives currently in use
- [ ] Identify third-party gems that depend on Sprockets
- [ ] Map asset loading patterns in views and layouts

```bash
# Find all asset files
find app/assets -name "*.css" -o -name "*.scss" -o -name "*.js" -o -name "*.coffee"

# Check for Sprockets directives
grep -r "//=" app/assets/
grep -r "*=" app/assets/
```

#### 1.2 Dependency Analysis
- [ ] List all gems that require Sprockets compatibility
- [ ] Research Propshaft-native alternatives
- [ ] Plan gem replacement strategy

```ruby
# Current problematic gems (example)
gem 'sassc-rails'          # Replace with: dartsass-rails
gem 'sprockets-rails'      # Remove entirely
gem 'sass-rails'           # Replace with: dartsass-rails
```

#### 1.3 Test Infrastructure
- [ ] Verify asset compilation tests exist
- [ ] Add specific tests for auto-refresh functionality
- [ ] Create asset loading performance benchmarks

### Phase 2: CSS Pipeline Migration (2-3 days)

#### 2.1 Remove Sass Dependencies
- [ ] Replace `sassc-rails` with `dartsass-rails`
- [ ] Update `Gemfile` and run `bundle install`
- [ ] Test basic CSS compilation

```ruby
# In Gemfile
# Remove:
# gem 'sassc-rails'

# Add:
gem 'dartsass-rails'
```

#### 2.2 Update CSS Import Syntax
- [ ] Convert Sprockets `@import` statements to CSS imports
- [ ] Update asset manifest files
- [ ] Ensure Tailwind CSS integration works

```css
/* Old Sprockets syntax */
/*
 *= require_tree .
 *= require_self
 */

/* New CSS import syntax */
@import 'tailwindcss/base';
@import 'tailwindcss/components';
@import 'tailwindcss/utilities';
@import 'components/buttons';
@import 'layouts/village';
```

#### 2.3 Verify CSS Compilation
- [ ] Test asset precompilation: `rails assets:precompile`
- [ ] Verify styles load correctly in development
- [ ] Check production asset serving
- [ ] Test CSS hot-reloading in development

### Phase 3: JavaScript Pipeline Migration (1-2 days)

#### 3.1 Update JavaScript Imports
- [ ] Convert Sprockets `//= require` to ES6 imports
- [ ] Update `app/javascript/application.js`
- [ ] Ensure Stimulus controllers load correctly

```javascript
// Old Sprockets syntax
//= require rails-ujs
//= require turbo
//= require_tree .

// New ES6 imports
import "@hotwired/turbo-rails"
import "./controllers"
```

#### 3.2 Verify JavaScript Functionality
- [ ] Test Turbo Stream functionality
- [ ] Verify Stimulus controllers work
- [ ] Check auto-refresh JavaScript
- [ ] Test background job UI updates

### Phase 4: Asset Configuration (1 day)

#### 4.1 Update Asset Configuration
- [ ] Remove Sprockets configuration from `application.rb`
- [ ] Update `config/initializers/assets.rb`
- [ ] Configure Propshaft-specific settings

```ruby
# config/application.rb
# Remove Sprockets configuration
# config.assets.precompile += %w( ... )

# Update for Propshaft
config.assets.path.unshift Rails.root.join("app/assets/stylesheets")
config.assets.path.unshift Rails.root.join("app/assets/javascripts")
```

#### 4.2 Update Asset Manifest
- [ ] Convert `app/assets/config/manifest.js` to Propshaft format
- [ ] Remove Sprockets-specific directives
- [ ] Add explicit asset declarations

```javascript
// Old manifest.js
//= link_tree ../images
//= link_directory ../stylesheets .css
//= link_directory ../javascripts .js

// New Propshaft manifest.js
//= link application.css
//= link application.js
//= link_tree ../images
```

### Phase 5: Remove Sprockets Dependencies (1 day)

#### 5.1 Clean Gemfile
- [ ] Remove `sprockets-rails` gem
- [ ] Remove other Sprockets-dependent gems
- [ ] Run `bundle install` and resolve conflicts

```ruby
# Remove from Gemfile:
# gem 'sprockets-rails'
# gem 'sassc-rails' 
# gem 'sass-rails'

# Keep or add:
gem 'propshaft'
gem 'dartsass-rails'
```

#### 5.2 Clean Configuration Files
- [ ] Remove Sprockets configuration from initializers
- [ ] Clean up asset-related configuration
- [ ] Remove unused asset directories

### Phase 6: Testing and Validation (2-3 days)

#### 6.1 Comprehensive Testing
- [ ] Run full test suite: `rspec`
- [ ] Specifically test: `rspec spec/system/village_auto_refresh_spec.rb`
- [ ] Test asset compilation: `rails assets:precompile`
- [ ] Test development auto-refresh functionality

#### 6.2 Performance Validation
- [ ] Benchmark asset compilation time
- [ ] Test production asset serving performance
- [ ] Verify browser caching works correctly
- [ ] Check asset file sizes

```bash
# Performance benchmarks
time rails assets:precompile
ls -lh public/assets/

# Test in production mode
RAILS_ENV=production rails server
# Verify assets load correctly
```

#### 6.3 Cross-Environment Testing
- [ ] Test in development environment
- [ ] Test in staging environment
- [ ] Test in production-like environment
- [ ] Verify Docker build with new assets

## Testing Strategy

### Automated Tests
```ruby
# Add to test suite
RSpec.describe 'Asset Pipeline' do
  it 'compiles assets without errors' do
    expect { Rails.application.assets.find_asset('application.css') }.not_to raise_error
  end

  it 'includes all required stylesheets' do
    asset = Rails.application.assets.find_asset('application.css')
    expect(asset.to_s).to include('tailwind')
  end
end

# Verify auto-refresh still works
RSpec.describe 'Village auto-refresh', type: :system, js: true do
  it 'updates resources automatically' do
    visit village_path(village)
    VillageLoopJob.perform_now(village.id)
    expect(page).to have_css('#resources-list', wait: 10)
  end
end
```

### Manual Testing Checklist
- [ ] Village page loads with correct styling
- [ ] Auto-refresh functionality works (resources update every 30 seconds)
- [ ] Building construction UI works correctly
- [ ] Turbo Stream updates display properly
- [ ] Mobile responsive design intact
- [ ] No console errors in browser developer tools

## Rollback Plan

### Immediate Rollback (if issues found quickly)
1. **Git Revert**:
   ```bash
   git revert <migration-commit-hash>
   git push origin main
   ```

2. **Gemfile Restoration**:
   ```ruby
   # Restore in Gemfile
   gem 'propshaft', '~> 1.1.0'
   gem 'sassc-rails'
   ```

3. **Asset Configuration Restoration**:
   - Restore previous `config/assets.rb`
   - Restore Sprockets configuration
   - Restore previous asset manifests

### Full Environment Rollback
1. **Deploy Previous Version**:
   ```bash
   kamal deploy --version=<previous-version>
   ```

2. **Database Considerations**:
   - No database changes expected
   - Asset-related data should be unchanged

### Data Recovery
- No data loss expected from asset pipeline changes
- Asset compilation can be regenerated
- Application state should be unaffected

## Success Criteria

### Technical Success
- [ ] All tests pass (unit, integration, system)
- [ ] Asset compilation works without errors
- [ ] Auto-refresh functionality maintains 30-second update cycle
- [ ] Page load times maintain or improve performance
- [ ] No JavaScript console errors

### Business Success
- [ ] Game functionality unchanged from user perspective
- [ ] Real-time updates continue working seamlessly
- [ ] Mobile experience remains responsive
- [ ] Deployment process unaffected

### Code Quality Success
- [ ] Gemfile simplified with fewer dependencies
- [ ] Asset configuration more maintainable
- [ ] Future Rails upgrades easier to implement
- [ ] Documentation updated with new patterns

## Post-Migration Tasks

### Documentation Updates
- [ ] Update README.md with new asset pipeline information
- [ ] Update development setup instructions
- [ ] Document new asset compilation process
- [ ] Update troubleshooting guides

### Monitoring Setup
- [ ] Monitor asset compilation times in CI/CD
- [ ] Set up alerts for asset-related errors
- [ ] Track page load performance metrics
- [ ] Monitor auto-refresh functionality

### Knowledge Transfer
- [ ] Train team on new asset pipeline
- [ ] Document differences from previous setup
- [ ] Share lessons learned
- [ ] Update onboarding documentation

## Lessons Learned Template

After migration completion, document:

### What Worked Well
- Specific approaches that were successful
- Tools and techniques that helped
- Team coordination strategies

### Challenges Encountered
- Unexpected issues and their solutions
- Time estimates vs. actual time needed
- Dependencies that caused problems

### Future Improvements
- What would be done differently next time
- Additional preparation that would help
- Process improvements for future migrations

---

**Next Steps After Completion**:
1. Create GitHub issue to track this migration
2. Schedule migration work in sprint planning
3. Assign team members to specific phases
4. Set up monitoring for migration progress

**Related Issues**:
- [Propshaft 1.2.0 Compatibility Issue](../troubleshooting/propshaft-compatibility-issue.md)
- [Asset Pipeline Architecture](../architecture/asset-pipeline.md)
