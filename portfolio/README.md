# Portfolio Content

This section showcases the Villager Rails project for portfolio and demonstration purposes.

## Project Overview

**Villager Rails** is a real-time village-building simulation game built with Ruby on Rails 8, demonstrating modern web development patterns and real-time architecture.

### Key Highlights

- **Real-time gameplay** with Turbo Streams for instant UI updates
- **Background job processing** for continuous game simulation
- **Modern asset pipeline** with Propshaft and compatibility layers
- **Comprehensive testing** with RSpec system and unit tests
- **Docker deployment** with Kamal for zero-downtime releases
- **Responsive design** with Tailwind CSS

## Technical Achievements

### Real-Time Architecture

Successfully implemented a real-time game engine using Rails-native technologies:

- **Turbo Streams**: Enables real-time resource updates without page refreshes
- **WebSocket connections**: Maintains live connections for instant gameplay feedback
- **Background job coordination**: Seamless integration between Sidekiq jobs and UI updates

```ruby
# Example: Real-time resource production
class ProduceResourcesFromBuildingService
  def call
    produce_resources
    broadcast_resource_updates # Real-time UI update
  end
  
  private
  
  def broadcast_resource_updates
    broadcast_replace_to(
      [@village, :resources],
      target: 'resources-list',
      partial: 'villages/resources_list',
      locals: { village: @village }
    )
  end
end
```

### Asset Pipeline Modernization

Navigated complex asset pipeline challenges during Rails 8 upgrade:

- **Problem**: Propshaft 1.2.0 compatibility issues broke asset compilation
- **Investigation**: Thorough analysis of dependency conflicts and compatibility layers
- **Solution**: Strategic pinning with documented migration path
- **Learning**: Deep understanding of modern Rails asset pipeline evolution

### Comprehensive Testing Strategy

Implemented robust testing covering critical real-time features:

```ruby
# System test for real-time functionality
RSpec.describe 'Village auto-refresh', type: :system, js: true do
  it 'updates resources automatically via background jobs' do
    visit village_path(village)
    
    # Trigger background job
    VillageLoopJob.perform_now(village.id)
    
    # Verify real-time UI update
    expect(page).to have_css('#resources-list', wait: 10)
  end
end
```

### Service-Oriented Architecture

Applied clean architecture principles with service objects:

- **Single Responsibility**: Each service handles one business operation
- **Testability**: Isolated business logic for comprehensive unit testing
- **Maintainability**: Clear separation between HTTP handling and game logic

## Screenshots and Demos

### Village Dashboard
![Village Dashboard](screenshots/village-dashboard.png)
*Real-time village overview with resource tracking and building management*

### Building Construction
![Building Construction](screenshots/building-construction.png)
*Interactive building placement with resource cost validation*

### Resource Production
![Resource Production](screenshots/resource-production.gif)
*Live resource generation demonstration (30-second GIF)*

### Mobile Responsive Design
![Mobile View](screenshots/mobile-responsive.png)
*Fully responsive design optimized for mobile gameplay*

## Development Process

### Problem-Solving Approach

**Asset Pipeline Crisis (December 2024)**:

1. **Issue Identification**: Automated dependency update broke critical functionality
2. **Root Cause Analysis**: Traced issue to Propshaft/Sprockets compatibility changes
3. **Solution Strategy**: Implemented immediate fix with long-term migration plan
4. **Documentation**: Created comprehensive troubleshooting guide for future reference

### Technical Decision Making

**Real-Time Architecture Choice**:
- **Evaluated**: WebSocket frameworks vs. Turbo Streams
- **Decided**: Turbo Streams for Rails-native simplicity
- **Trade-off**: Some flexibility for development speed and maintainability
- **Result**: Successful real-time gameplay with minimal complexity

### Continuous Improvement

**Testing Philosophy**:
- **System tests** for critical user journeys
- **Unit tests** for business logic
- **Performance monitoring** for background jobs
- **Real-time feature validation** for core gameplay

## Code Quality

### Architecture Patterns

- **Service Objects**: Clean business logic encapsulation
- **Background Jobs**: Reliable asynchronous processing
- **Factory Pattern**: Consistent test data creation
- **Repository Pattern**: ActiveRecord with custom query methods

### Best Practices Demonstrated

- **SOLID principles** in service object design
- **DRY (Don't Repeat Yourself)** in view partials and helpers
- **Convention over Configuration** following Rails standards
- **Test-Driven Development** for critical features

## Learning Outcomes

### Technical Skills Developed

1. **Real-Time Web Applications**
   - Turbo Streams implementation
   - WebSocket connection management
   - Background job coordination

2. **Modern Rails Development**
   - Rails 8 features and patterns
   - Asset pipeline management
   - Hotwire (Turbo + Stimulus) integration

3. **Testing Expertise**
   - System test automation with Capybara
   - Background job testing strategies
   - Real-time feature validation

4. **DevOps and Deployment**
   - Docker containerization
   - Kamal deployment automation
   - Asset pipeline optimization

### Problem-Solving Skills

- **Dependency Management**: Understanding complex gem interdependencies
- **Performance Optimization**: Database query optimization and caching
- **Debugging**: Systematic approach to complex real-time issues
- **Documentation**: Creating comprehensive troubleshooting guides

## Project Impact

### Technical Innovation

- Demonstrated successful real-time game implementation with Rails
- Created reusable patterns for background job + UI coordination
- Developed robust testing strategies for JavaScript-heavy features

### Knowledge Sharing

- Comprehensive documentation for team learning
- Troubleshooting guides for common issues
- Architecture decisions documented with rationale

### Portfolio Value

This project demonstrates:
- **Full-stack development** with modern Rails
- **Real-time application** architecture
- **Problem-solving skills** under pressure
- **Testing and deployment** expertise
- **Documentation and communication** abilities

## Code Repository

**Main Application**: [villager_rails_2](https://github.com/your-org/villager_rails_2)  
**Documentation**: [villager_rails_learning](https://github.com/your-org/villager_rails_learning)

### Key Files to Review

- **Real-time logic**: `app/services/village_loop_service.rb`
- **Background jobs**: `app/jobs/village_loop_job.rb`
- **Testing examples**: `spec/system/village_auto_refresh_spec.rb`
- **Asset configuration**: `app/assets/config/manifest.js`
- **Deployment setup**: `config/deploy.yml`

## Future Enhancements

### Planned Features

1. **Multi-player interactions**: Village trading and diplomacy
2. **Advanced building system**: Technology trees and upgrades
3. **Mobile app**: Native iOS/Android companion
4. **Performance optimization**: Real-time analytics and monitoring

### Technical Improvements

1. **Asset pipeline migration**: Complete Propshaft adoption
2. **Caching layer**: Redis for game state caching
3. **API development**: External integrations and mobile support
4. **Monitoring**: Application performance monitoring (APM)

---

*This project showcases the intersection of modern web development, real-time architecture, and game design, demonstrating both technical expertise and creative problem-solving abilities.*
