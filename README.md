# Villager Rails Learning Repository

A comprehensive documentation and learning resource repository for the **Villager Rails** village-building game project. This repository focuses on design patterns, architectural decisions, and hands-on coding exercises for Ruby on Rails development.

## 🎮 About Villager Rails

Villager Rails is a real-time village-building game built with Ruby on Rails 8, featuring:

- **Real-time simulation** with automatic resource generation
- **Modern Rails stack**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Background processing** with Sidekiq for game loops
- **Live updates** via Turbo Streams
- **Comprehensive testing** with RSpec and Capybara
- **Docker deployment** with Kamal

## 📚 What's Inside

### Design Patterns Documentation

#### 🔧 Service Objects Pattern
Complete coverage of the Service Objects pattern with community insights:

- **[Overview & Key Writings](design-patterns/service-objects/README.md)** - Core concepts and community knowledge
- **[Implementation Examples](design-patterns/service-objects/implementation-examples.md)** - Real-world code examples
- **[Advanced Patterns](design-patterns/service-objects/advanced-patterns.md)** - Complex techniques and sophisticated patterns
- **[Critical Analysis](design-patterns/service-objects/critical-analysis.md)** - Community debates and alternatives

#### ⚙️ Background Jobs Pattern
Comprehensive documentation on background job processing:

- **[Overview & Strategies](design-patterns/background-jobs/README.md)** - Core concepts and queue strategies
- **[Implementation Examples](design-patterns/background-jobs/implementation-examples.md)** - Practical job patterns
- **[Advanced Patterns](design-patterns/background-jobs/advanced-patterns.md)** - Idempotency and orchestration

### 🎯 Hands-On Learning

#### TDD-Ready Coding Drills
**[Service Objects Drills](design-patterns/service-objects/drills/)** - Five progressive coding exercises:

1. **[Basic Service Structure](design-patterns/service-objects/drills/01-basic-service-structure/)** - Foundation patterns
2. **[Service Concerns](design-patterns/service-objects/drills/02-service-concerns/)** - Reusable functionality
3. **[Command Patterns](design-patterns/service-objects/drills/03-proc-based-commands/)** - Flexible operations
4. **[Advanced Results](design-patterns/service-objects/drills/04-advanced-result-objects/)** - Rich data structures
5. **[Idempotent Services](design-patterns/service-objects/drills/05-idempotent-services/)** - Production-ready patterns

Each drill includes:
- Complete problem description and learning goals
- Starter code files to edit
- Comprehensive test suites (TDD-ready)
- Supporting files (models, migrations, concerns)

#### Quick Start for Drills
```bash
# Clone and navigate to any drill
git clone https://github.com/yourusername/villager-rails-learning.git
cd villager-rails-learning/design-patterns/service-objects/drills/01-basic-service-structure/

# Run tests to see what needs implementing
bundle exec rspec creation_service_spec.rb

# Edit the starter file to make tests pass
# creation_service.rb
```

## 🏗️ Technology Stack Context

The documentation is tailored for the Villager Rails tech stack:

- **Backend**: Ruby on Rails 8, Sidekiq for background jobs
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS  
- **Asset Pipeline**: Propshaft (with compatibility considerations)
- **Database**: PostgreSQL with Active Record
- **Testing**: RSpec with system tests using Capybara
- **Deployment**: Docker with Kamal

## 📖 Learning Path

### For Beginners
1. Start with [Service Objects Overview](design-patterns/service-objects/README.md)
2. Work through [Basic Service Structure drill](design-patterns/service-objects/drills/01-basic-service-structure/)
3. Progress through remaining drills sequentially

### For Experienced Developers
1. Review [Advanced Patterns](design-patterns/service-objects/advanced-patterns.md)
2. Explore [Critical Analysis](design-patterns/service-objects/critical-analysis.md) for alternative perspectives
3. Tackle advanced drills: [Command Patterns](design-patterns/service-objects/drills/03-proc-based-commands/) and [Idempotent Services](design-patterns/service-objects/drills/05-idempotent-services/)

### For Architecture Decisions
1. Study [Implementation Examples](design-patterns/service-objects/implementation-examples.md)
2. Review community insights in [Background Jobs](design-patterns/background-jobs/README.md)
3. Apply patterns to your own Rails projects

## 🤝 Contributing

This is a learning and documentation repository. Contributions welcome for:

- Additional coding drills and exercises
- Real-world implementation examples
- Documentation improvements
- Community pattern discussions

## 📚 External Resources

The documentation synthesizes knowledge from leading Rails community voices:
- Amin Shah Gilani (Toptal)
- Nicholaus Haskins  
- Jason Swett (RailsTest)
- GoRails community patterns
- Sidekiq best practices

## 🔗 Related Projects

- **[Villager Rails Main Application](https://github.com/sandy-codes/villager_rails_2)** - The actual game implementation
- **Rails Design Patterns** - Broader pattern discussions

## Repository Structure

```
├── design-patterns/         # Design patterns and architectural decisions
│   ├── service-objects/    # Complete service objects documentation
│   │   └── drills/        # TDD-ready coding exercises
│   └── background-jobs/    # Background job patterns
├── architecture/           # High-level architecture documentation  
├── coding-patterns/       # Code examples and best practices
├── learning-resources/    # Tutorials, guides, and reference materials
├── portfolio/            # Screenshots, demos, and portfolio content
├── troubleshooting/      # Common issues and solutions
└── migration-guides/     # Upgrade and migration documentation
```

## Contributing

This is a personal learning repository, but feedback and suggestions are welcome through issues or discussions.

## License

This documentation is shared under the MIT License. See the main project repository for code licensing.

---

*Last updated: December 2024*
