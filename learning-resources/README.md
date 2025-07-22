# Learning Resources

Comprehensive guides and tutorials for understanding and working with the Villager Rails project.

## Table of Contents

- [Getting Started](#getting-started)
- [Core Concepts](#core-concepts)
- [Advanced Topics](#advanced-topics)
- [External Resources](#external-resources)

## Getting Started

### Prerequisites

Before diving into the Villager Rails project, you should have a solid understanding of:

- **Ruby on Rails 7+**: MVC architecture, Active Record, routing
- **Modern JavaScript**: ES6+, async/await, DOM manipulation
- **HTML/CSS**: Semantic markup, responsive design
- **Git**: Version control, branching, pull requests
- **SQL**: Basic queries, joins, indexes

### Development Environment Setup

1. **Ruby and Rails**:
   ```bash
   # Install Ruby 3.2+ (using rbenv recommended)
   rbenv install 3.2.0
   rbenv global 3.2.0
   
   # Install Rails 8
   gem install rails -v 8.0.0
   ```

2. **Database Setup**:
   ```bash
   # Install PostgreSQL
   # macOS: brew install postgresql
   # Ubuntu: sudo apt-get install postgresql postgresql-contrib
   
   # Start PostgreSQL service
   # macOS: brew services start postgresql
   # Ubuntu: sudo systemctl start postgresql
   ```

3. **Redis for Background Jobs**:
   ```bash
   # Install Redis
   # macOS: brew install redis
   # Ubuntu: sudo apt-get install redis-server
   
   # Start Redis
   redis-server
   ```

4. **Project Setup**:
   ```bash
   git clone https://github.com/your-org/villager_rails_2.git
   cd villager_rails_2
   bundle install
   rails db:setup
   ```

### First Steps

1. **Run the Application**:
   ```bash
   # Terminal 1: Start Rails server
   rails server
   
   # Terminal 2: Start Sidekiq for background jobs
   bundle exec sidekiq
   
   # Terminal 3: Start asset watching (if needed)
   rails assets:watch
   ```

2. **Create Your First Village**:
   - Visit `http://localhost:3000`
   - Sign up for an account
   - Create a new village
   - Add some buildings
   - Watch resources generate automatically

3. **Explore the Code**:
   - **Models**: Start with `app/models/village.rb`
   - **Controllers**: Look at `app/controllers/villages_controller.rb`
   - **Views**: Examine `app/views/villages/show.html.erb`
   - **Jobs**: Understand `app/jobs/village_loop_job.rb`

## Core Concepts

### Real-Time Game Architecture

The Villager Rails project implements a real-time village simulation using several key technologies:

#### Turbo Streams for Real-Time Updates

Turbo Streams enable real-time UI updates without page refreshes:

```ruby
# In a service object
def broadcast_resource_updates
  broadcast_replace_to(
    [@village, :resources],
    target: 'resources-list',
    partial: 'villages/resources_list',
    locals: { village: @village }
  )
end
```

```erb
<!-- In the view -->
<%= turbo_stream_from [@village, :resources] %>
<div id="resources-list">
  <%= render 'resources_list', village: @village %>
</div>
```

**Learning Path**:
1. Read [Turbo Handbook](https://turbo.hotwired.dev/)
2. Study `app/views/villages/show.html.erb`
3. Examine Turbo Stream templates in `app/views/village_buildings/`
4. Practice with [Turbo Stream Broadcasting Guide](turbo-streams-guide.md)

#### Background Job Processing

Game mechanics run continuously via background jobs:

```ruby
# Recurring job that processes all villages
class PlayLoopJob < ApplicationJob
  def perform
    Village.active.find_each do |village|
      VillageLoopJob.perform_later(village.id)
    end
  end
end

# Individual village processing
class VillageLoopJob < ApplicationJob
  def perform(village_id)
    village = Village.find(village_id)
    VillageLoopService.new(village).call
  end
end
```

**Learning Path**:
1. Study [Sidekiq documentation](https://sidekiq.org/)
2. Understand `config/recurring.yml` configuration
3. Explore service objects in `app/services/`
4. Practice with [Background Jobs Guide](background-jobs-guide.md)

#### Service Objects Pattern

Business logic is encapsulated in service objects:

```ruby
class ProduceResourcesFromBuildingService
  def initialize(village_building)
    @village_building = village_building
    @village = village_building.village
  end

  def call
    return false unless can_produce?
    
    produce_resources
    update_production_timestamp
    broadcast_updates
    true
  end
  
  private
  
  # Implementation details...
end
```

**Learning Path**:
1. Read about [Service Objects pattern](https://blog.appsignal.com/2020/06/17/using-service-objects-in-ruby-on-rails.html)
2. Study existing services in `app/services/`
3. Understand the [Single Responsibility Principle](https://en.wikipedia.org/wiki/Single-responsibility_principle)
4. Practice with [Service Objects Guide](service-objects-guide.md)

### Game Mechanics

#### Resource System

Villages have resources that are consumed and produced:

```ruby
class Village < ApplicationRecord
  def resource_amount(resource_name)
    village_resources.joins(:resource)
                    .where(resources: { name: resource_name })
                    .sum(:amount)
  end

  def can_afford?(costs)
    costs.all? { |cost| resource_amount(cost.resource.name) >= cost.amount }
  end
end
```

#### Building System

Buildings consume resources to construct and produce resources over time:

```ruby
class Building < ApplicationRecord
  has_many :costs, dependent: :destroy
  has_many :building_outputs, dependent: :destroy
  
  def can_be_built_by?(village)
    village.can_afford?(costs)
  end
end
```

### Testing Strategy

The project uses comprehensive testing with RSpec:

#### System Tests for Real-Time Features

```ruby
RSpec.describe 'Village auto-refresh', type: :system, js: true do
  it 'updates resources automatically' do
    visit village_path(village)
    
    # Wait for background job to run
    VillageLoopJob.perform_now(village.id)
    
    # Verify UI updates via Turbo Stream
    expect(page).to have_css('#resources-list', wait: 10)
  end
end
```

#### Service Object Testing

```ruby
RSpec.describe ProduceResourcesFromBuildingService do
  it 'produces resources when conditions are met' do
    service = described_class.new(village_building)
    
    expect { service.call }.to change { village.resource_amount('Wood') }.by(10)
  end
end
```

**Learning Path**:
1. Study [RSpec documentation](https://rspec.info/)
2. Learn [Capybara for system tests](https://github.com/teamcapybara/capybara)
3. Understand [FactoryBot](https://github.com/thoughtbot/factory_bot)
4. Practice with [Testing Guide](testing-guide.md)

## Advanced Topics

### Performance Optimization

- **Database Optimization**: Indexes, query optimization, N+1 prevention
- **Caching Strategies**: Fragment caching, counter caching, Redis caching
- **Asset Pipeline**: Efficient CSS/JS bundling and delivery
- **Background Job Optimization**: Queue management, retry strategies

**Learning Resources**:
- [Performance Guide](performance-guide.md)
- [Database Optimization](database-optimization.md)
- [Caching Strategies](caching-guide.md)

### Deployment and DevOps

- **Docker Containerization**: Multi-stage builds, volume management
- **Kamal Deployment**: Zero-downtime deployments, rolling updates
- **Monitoring**: Application monitoring, error tracking, performance metrics
- **Security**: Authentication, authorization, input validation

**Learning Resources**:
- [Deployment Guide](deployment-guide.md)
- [Docker Best Practices](docker-guide.md)
- [Security Checklist](security-guide.md)

### Architecture Patterns

- **Domain-Driven Design**: Organizing code around business domains
- **CQRS**: Command Query Responsibility Segregation for complex operations
- **Event Sourcing**: Recording state changes as events
- **Microservices**: Breaking down monolithic applications

**Learning Resources**:
- [Architecture Patterns](architecture-patterns.md)
- [Domain Modeling](domain-modeling.md)
- [Scalability Planning](scalability-guide.md)

## External Resources

### Ruby on Rails

- [Official Rails Guides](https://guides.rubyonrails.org/)
- [Rails API Documentation](https://api.rubyonrails.org/)
- [Hotwire Documentation](https://hotwired.dev/)
- [Rails 8 Release Notes](https://guides.rubyonrails.org/8_0_release_notes.html)

### Testing

- [RSpec Documentation](https://rspec.info/documentation/)
- [Capybara Documentation](https://github.com/teamcapybara/capybara)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot)
- [Testing Rails Applications Guide](https://guides.rubyonrails.org/testing.html)

### Frontend Technologies

- [Turbo Documentation](https://turbo.hotwired.dev/)
- [Stimulus Documentation](https://stimulus.hotwired.dev/)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [MDN Web Docs](https://developer.mozilla.org/)

### Background Jobs

- [Sidekiq Documentation](https://sidekiq.org/)
- [Active Job Guide](https://guides.rubyonrails.org/active_job_basics.html)
- [Redis Documentation](https://redis.io/documentation)

### Deployment

- [Kamal Documentation](https://kamal-deploy.org/)
- [Docker Documentation](https://docs.docker.com/)
- [Heroku Rails Guide](https://devcenter.heroku.com/articles/getting-started-with-rails8)

### Books and Courses

- **"The Rails Way"** by Obie Fernandez
- **"Effective Testing with RSpec 3"** by Myron Marston
- **"Agile Web Development with Rails 7"** by Sam Ruby
- **"Service-Oriented Design with Ruby and Rails"** by Paul Dix

## Contributing to Learning Resources

This documentation is a living resource. To contribute:

1. **Identify Knowledge Gaps**: What concepts need better explanation?
2. **Add Examples**: Provide clear, working code examples
3. **Update External Links**: Keep references current and accessible
4. **Share Insights**: Document lessons learned from development

## Next Steps

After familiarizing yourself with these concepts:

1. **Build Features**: Implement new game mechanics
2. **Optimize Performance**: Improve response times and scalability
3. **Enhance Testing**: Add comprehensive test coverage
4. **Explore Integrations**: Connect with external APIs or services
5. **Document Learning**: Share your discoveries with the team

---

*Happy learning! The Villager Rails project offers a rich environment for exploring modern web development patterns and real-time application architecture.*
