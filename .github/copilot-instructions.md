<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Copilot Instructions for Villager Rails Learning Repository

## Project Context
This is a documentation and learning repository for the Villager Rails village-building game project. The main application is a Rails 8 real-time game with the following technology stack:

### Core Technologies
- **Backend**: Ruby on Rails 8, Sidekiq for background jobs
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Asset Pipeline**: Propshaft (with Sprockets compatibility layer)
- **Database**: PostgreSQL with Active Record
- **Testing**: RSpec with system tests using Capybara
- **Deployment**: Docker with Kamal

### Key Features
- Real-time village simulation with automatic resource generation
- Turbo Stream updates for live UI updates
- Background job processing for game loops
- Comprehensive test coverage
- Modern responsive design

## Documentation Guidelines

When helping with documentation:

1. **Architecture Documentation**: Focus on high-level system design, data flow, and component interactions
2. **Design Patterns**: Document architectural decisions, trade-offs, and rationale
3. **Code Examples**: Provide clear, well-commented examples with context
4. **Learning Resources**: Create step-by-step guides and tutorials
5. **Troubleshooting**: Document common issues with clear solutions

## Writing Style

- Use clear, concise language suitable for learning
- Include code examples with explanations
- Provide context for architectural decisions
- Link to relevant external resources
- Use diagrams where helpful (Mermaid syntax preferred)

## Content Organization

- Each major topic should have its own directory with a README.md
- Use consistent file naming conventions
- Include cross-references between related topics
- Maintain a logical information hierarchy

## Code Examples

When providing code examples:
- Use Ruby/Rails conventions and best practices
- Include relevant context (file paths, setup requirements)
- Explain the purpose and benefits of the approach
- Show both the "what" and the "why"

## Asset Pipeline Context

The project recently underwent a Propshaft upgrade that revealed compatibility issues. Key considerations:
- Propshaft 1.2.0 breaks compatibility with sassc-rails
- Currently pinned to Propshaft 1.1.0 for stability
- Future migration to pure Propshaft pipeline planned
- Asset compilation and auto-refresh features are critical

This context is important for any asset-related documentation or troubleshooting guides.
