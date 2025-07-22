# Troubleshooting Guide

Common issues and solutions encountered during Villager Rails development.

## Asset Pipeline Issues

### Propshaft 1.2.0 Compatibility Problem

**Problem**: After upgrading to Propshaft 1.2.0, asset compilation fails and auto-refresh stops working.

**Symptoms**:
- Asset precompilation errors during deployment
- CSS/JS files not loading in development
- Auto-refresh functionality broken
- System tests failing due to missing assets

**Root Cause**: Propshaft 1.2.0 removed Sprockets compatibility layer that sassc-rails depends on.

**Solution**:
```ruby
# In Gemfile, pin Propshaft to working version
gem 'propshaft', '~> 1.1.0'

# Run bundle update to apply the pin
bundle update propshaft
```

**Verification**:
```bash
# Check asset compilation works
rails assets:precompile

# Verify auto-refresh in development
rails server
# Visit village page and check for resource updates

# Run system tests
rspec spec/system/village_auto_refresh_spec.rb
```

**Long-term Plan**:
- Create migration plan to pure Propshaft pipeline
- Remove sassc-rails dependency
- Implement CSS compilation without Sprockets
- See [Propshaft Migration Plan](../migration-guides/propshaft-migration.md)

## Real-Time Update Issues

### Turbo Streams Not Broadcasting

**Problem**: Resource updates happening in background but UI not refreshing.

**Symptoms**:
- Database shows updated resource amounts
- Page refresh shows correct values
- No real-time updates in browser

**Common Causes**:

1. **Missing Turbo Stream Channel Subscription**:
```erb
<!-- In village show view -->
<%= turbo_stream_from [@village, :resources] %>
```

2. **Incorrect Target Element**:
```erb
<!-- Ensure target exists in DOM -->
<div id="resources-list">
  <%= render 'resources_list', village: @village %>
</div>
```

3. **Service Not Broadcasting**:
```ruby
# In service object
def broadcast_resource_updates
  broadcast_replace_to(
    [@village, :resources],
    target: 'resources-list',
    partial: 'villages/resources_list',
    locals: { village: @village.reload } # Important: reload data
  )
end
```

### Background Jobs Not Running

**Problem**: Game loop not executing, resources not generating.

**Debugging Steps**:

1. **Check Sidekiq is Running**:
```bash
# In development
bundle exec sidekiq

# Check for running jobs
rails console
Sidekiq::Queue.new.size
```

2. **Verify Job Scheduling**:
```bash
# Check recurring job configuration
cat config/recurring.yml

# Manually trigger job
rails console
PlayLoopJob.perform_now
```

3. **Check Job Errors**:
```bash
# View Sidekiq web interface
bundle exec sidekiq
# Visit http://localhost:4567/sidekiq
```

**Common Fixes**:
- Ensure Redis is running: `redis-server`
- Check job queue configuration in `config/application.rb`
- Verify recurring job gem is properly configured

## Database Issues

### Migration Problems

**Problem**: Database schema out of sync or migration failures.

**Solutions**:

1. **Reset Development Database**:
```bash
rails db:drop db:create db:migrate db:seed
```

2. **Check Migration Status**:
```bash
rails db:migrate:status
```

3. **Rollback Problematic Migration**:
```bash
rails db:rollback STEP=1
```

### Performance Issues

**Problem**: Slow queries or N+1 query problems.

**Debugging**:

1. **Enable Query Logging**:
```ruby
# In development.rb
config.active_record.verbose_query_logs = true
```

2. **Use Bullet Gem**:
```ruby
# In Gemfile (development group)
gem 'bullet'

# In development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.bullet_logger = true
  Bullet.console = true
end
```

3. **Profile Slow Queries**:
```ruby
# In Rails console
Village.includes(:village_resources, :village_buildings).limit(10).explain
```

## Testing Issues

### System Test Failures

**Problem**: JavaScript-dependent tests failing intermittently.

**Common Issues**:

1. **Race Conditions**:
```ruby
# Use proper waiting strategies
expect(page).to have_css('#resources-list', wait: 10)

# Wait for specific content
expect(page).to have_content('Wood: 100', wait: 15)
```

2. **Headless Chrome Issues**:
```ruby
# In rails_helper.rb
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] do |driver_options|
      driver_options.add_argument('--disable-dev-shm-usage')
      driver_options.add_argument('--no-sandbox')
    end
  end
end
```

3. **Capybara Configuration**:
```ruby
# In rails_helper.rb
Capybara.configure do |config|
  config.default_max_wait_time = 10
  config.server = :puma, { Silent: true }
end
```

### Factory Issues

**Problem**: Factory creation failing or creating invalid objects.

**Solutions**:

1. **Check Factory Definitions**:
```ruby
# Test factories in console
rails console
FactoryBot.create(:village, :with_resources)
```

2. **Validate Associations**:
```ruby
# Ensure all required associations exist
factory :village_building do
  village
  building
  tile { village.tiles.available.first || create(:tile, village: village) }
end
```

## Development Environment Issues

### Docker Problems

**Problem**: Container build failures or service connectivity issues.

**Common Solutions**:

1. **Clean Docker Cache**:
```bash
docker system prune -a
docker-compose down -v
docker-compose up --build
```

2. **Database Connection Issues**:
```bash
# Check database container is running
docker-compose ps

# Reset database in container
docker-compose exec web rails db:reset
```

3. **Asset Problems in Docker**:
```dockerfile
# Ensure proper asset handling in Dockerfile
RUN rails assets:precompile
```

### Development Server Issues

**Problem**: Rails server not starting or crashing.

**Debugging Steps**:

1. **Check Port Conflicts**:
```bash
lsof -i :3000
kill -9 <PID>
```

2. **Clear Temporary Files**:
```bash
rm -rf tmp/cache tmp/pids tmp/sockets
rails tmp:clear
```

3. **Bundle Issues**:
```bash
bundle install
bundle update
```

## Performance Debugging

### Slow Page Loads

**Investigation**:

1. **Use Rails Performance Tools**:
```ruby
# Add to controller
around_action :profile_performance

private

def profile_performance
  result = RubyProf.profile do
    yield
  end
  
  printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT)
end
```

2. **Database Query Analysis**:
```ruby
# In Rails console
ActiveRecord::Base.logger = Logger.new(STDOUT)
Village.includes(:village_resources).first
```

3. **Memory Usage**:
```bash
# Monitor memory during development
top -p $(pgrep -f rails)
```

## Deployment Issues

### Kamal Deployment Problems

**Problem**: Deployment failing or service not accessible.

**Common Fixes**:

1. **Check Deployment Configuration**:
```yaml
# config/deploy.yml
service: villager-rails
image: villager-rails
servers:
  - your-server-ip

registry:
  server: registry.digitalocean.com
  username: your-username
  password: your-password
```

2. **Asset Precompilation**:
```bash
# Ensure assets compile before deployment
RAILS_ENV=production rails assets:precompile
```

3. **Environment Variables**:
```bash
# Check all required env vars are set
kamal env show
```

## Getting Help

### Debug Information to Collect

When reporting issues, include:

1. **Environment Details**:
```bash
ruby --version
rails --version
bundle list
```

2. **Error Messages**:
- Full stack traces
- Browser console errors
- Server logs

3. **Reproduction Steps**:
- Minimal steps to reproduce
- Expected vs actual behavior
- Environment (development/production)

### Useful Commands

```bash
# Generate debug information
rails about
bundle exec rails zeitwerk:check

# Check system dependencies
rails runner "puts Rails.application.config.inspect"

# Database diagnostics
rails db:environment
rails db:version
```

## Related Documentation

- [Asset Pipeline Architecture](../architecture/asset-pipeline.md)
- [Migration Guides](../migration-guides/README.md)
- [Performance Optimization](../learning-resources/performance-guide.md)
