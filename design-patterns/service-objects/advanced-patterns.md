# Advanced Service Object Patterns

This document explores advanced patterns and techniques for service objects, including concerns, application service patterns, output objects, namespacing, and idempotency considerations.

## Concerns as an Alternative to Service Objects

### When to Use Concerns vs Service Objects

The choice between concerns and service objects represents a fundamental architectural decision about where to place shared behavior. Understanding when to use each pattern helps maintain clean, maintainable code.

**Concerns** are best for shared behavior across multiple models or classes. They excel at adding common functionality that feels like a natural extension of the objects they're mixed into:
```ruby
# app/models/concerns/trackable.rb
module Trackable
  extend ActiveSupport::Concern
  
  included do
    after_create :track_creation
    after_update :track_update
  end
  
  def track_creation
    Analytics.track(self, :created)
  end
  
  def track_update
    Analytics.track(self, :updated)
  end
end

# Usage in models
class User < ApplicationRecord
  include Trackable
end

class Village < ApplicationRecord
  include Trackable
end
```

**What this does:** The `Trackable` concern adds analytics tracking behavior to any model that includes it. It automatically tracks creation and update events using Rails callbacks.

**Why it's useful:** Instead of duplicating tracking code across multiple models, this concern provides a reusable solution that maintains the Single Responsibility Principle. The behavior feels natural to the objects that include it.

**Trade-offs:**
- ✅ **Pros:** Eliminates code duplication, maintains object-oriented feel, easy to apply to multiple models
- ❌ **Cons:** Creates implicit dependencies, harder to test in isolation, can lead to callback soup if overused

**Service Objects** are better for complex business operations that don't naturally belong to any single model:
```ruby
# app/services/user_registration_service.rb
class UserRegistrationService
  def initialize(params)
    @params = params
  end
  
  def call
    create_user
    send_welcome_email
    track_registration
    setup_default_village
  end
  
  private
  
  def create_user
    @user = User.create!(@params)
  end
  
  # ... other methods
end
```

**What this does:** This service orchestrates the complete user registration process, coordinating multiple operations across different domain boundaries.

**Why it's useful:** User registration involves multiple models (User, Village), external services (email), and analytics. This complexity doesn't belong in a controller or any single model, making a service object the natural choice.

**Trade-offs:**
- ✅ **Pros:** Explicit workflow, easy to test, clear separation of concerns, reusable from different contexts
- ❌ **Cons:** Additional class to maintain, can become complex if not properly decomposed

### Hybrid Approach: Service Objects with Concerns

The most powerful approach combines both patterns, using concerns to add common functionality to service objects themselves:

```ruby
# app/models/concerns/service_callable.rb
module ServiceCallable
  extend ActiveSupport::Concern
  
  class_methods do
    def call(*args)
      new(*args).call
    end
  end
  
  def call
    raise NotImplementedError, "Service must implement #call method"
  end
end

# Usage in service objects
class VillageUpdateService
  include ServiceCallable
  
  def initialize(village)
    @village = village
  end
  
  def call
    # Implementation here
  end
end

# Now you can call: VillageUpdateService.call(village)
```

**What this does:** The `ServiceCallable` concern provides a standardized interface for all service objects, allowing both class-level and instance-level invocation while enforcing the `call` method contract.

**Why it's useful:** This creates consistency across your service layer. You can call services either way: `ServiceClass.call(args)` or `ServiceClass.new(args).call`, providing flexibility for different use cases.

**Trade-offs:**
- ✅ **Pros:** Consistent API, enforces interface contract, reduces boilerplate
- ❌ **Cons:** Adds indirection, hides object creation from caller

## Autoloading and Reloading Constants

### Understanding Rails Autoloading with Service Objects

Rails autoloading behavior differs significantly between development and production environments, which can cause subtle bugs when dynamically loading service objects. Understanding these differences is crucial for robust service architectures.

Rails autoloading works differently in development vs production:

```ruby
# In development - this reloads automatically
class DynamicServiceLoader
  def self.load_service(service_name)
    service_class = "#{service_name.camelize}Service".constantize
    service_class.new
  rescue NameError
    Rails.logger.error "Service #{service_name} not found"
    nil
  end
end

# Better approach - explicit loading
class ServiceRegistry
  def self.services
    @services ||= {
      village_update: VillageUpdateService,
      resource_production: ResourceProductionService,
      building_construction: BuildingConstructionService
    }
  end
  
  def self.get(service_name)
    services[service_name]&.new
  end
end
```

**What this does:** The first approach uses `constantize` to dynamically load service classes by name. The second approach uses an explicit registry of known services.

**Why the registry is better:** 
- **Development reliability:** `constantize` can fail unpredictably when Rails reloads classes
- **Production safety:** All services are explicitly loaded at boot time, preventing missing constant errors
- **Visibility:** You can see all available services in one place
- **Performance:** No string manipulation or constant resolution at runtime

**Trade-offs:**
- ✅ **Registry pros:** Predictable, fast, explicit, easier to debug
- ❌ **Registry cons:** Must remember to add new services, more verbose
- ✅ **Dynamic pros:** Automatic discovery, less maintenance
- ❌ **Dynamic cons:** Runtime failures, slower, harder to debug autoloading issues

### Namespace Autoloading Considerations

Organizing services into namespaces improves code organization but requires understanding Rails' autoloading conventions:

```ruby
# app/services/villages/update_service.rb
module Villages
  class UpdateService
    include ServiceCallable
    
    def call
      # Implementation
    end
  end
end

# app/services/buildings/construct_service.rb
module Buildings
  class ConstructService
    include ServiceCallable
    
    def call
      # Implementation
    end
  end
end

# Usage
Villages::UpdateService.call(village)
Buildings::ConstructService.call(building_params)
```

**What this does:** Services are organized into domain-specific namespaces that mirror the file structure. Rails autoloading automatically maps `Villages::UpdateService` to `app/services/villages/update_service.rb`.

**Why it's useful:**
- **Organization:** Related services are grouped together logically
- **Namespace collision prevention:** Avoids naming conflicts between domains
- **Clear intent:** The namespace immediately communicates the service's domain
- **Scalability:** Easy to find and organize services as the application grows

**Trade-offs:**
- ✅ **Pros:** Better organization, prevents naming conflicts, scales well
- ❌ **Cons:** Longer class names, deeper directory structure, potential autoloading complexity in edge cases

## Using Proc.call Pattern

### Functional Service Pattern

The proc pattern brings functional programming concepts to service objects, creating reusable operations that can be composed and passed around like data. This approach is particularly powerful for building flexible, composable systems.

```ruby
# Functional approach with procs
class FunctionalVillageService
  def self.update_resources
    ->(village, resources) {
      village.transaction do
        resources.each do |resource_type, amount|
          village.add_resource(resource_type, amount)
        end
        village.broadcast_updates
      end
    }
  end
  
  def self.consume_resources
    ->(village, costs) {
      return false unless village.can_afford?(costs)
      
      village.transaction do
        costs.each do |cost|
          village.consume_resource(cost.resource, cost.amount)
        end
      end
      true
    }
  end
end

# Usage
update_proc = FunctionalVillageService.update_resources
update_proc.call(village, { wood: 10, stone: 5 })

consume_proc = FunctionalVillageService.consume_resources
success = consume_proc.call(village, building_costs)
```

**What this does:** Instead of traditional service objects, this creates procs (anonymous functions) that encapsulate specific operations. Each proc is a self-contained unit of work that can be stored, passed around, and executed.

**Why it's useful:**
- **Composability:** Procs can be easily combined, chained, or conditionally executed
- **Functional style:** Encourages immutable data and pure functions
- **Flexibility:** Operations can be stored in variables, passed to other methods, or dynamically selected
- **Testing:** Each proc can be tested independently as a unit

**Trade-offs:**
- ✅ **Pros:** Highly composable, functional style, lightweight, easy to test individual operations
- ❌ **Cons:** Less familiar to Ruby developers, harder to debug stack traces, can be overused leading to complex proc chains

### Command Pattern with Procs

The command pattern implemented with procs creates a flexible system for executing and potentially undoing operations. This is particularly valuable for game mechanics where players might want to undo actions.

```ruby
class VillageCommandService
  def initialize(village)
    @village = village
  end
  
  def commands
    {
      add_building: ->(building_type, position) {
        building = @village.buildings.create!(type: building_type, position: position)
        @village.broadcast_building_added(building)
        building
      },
      
      upgrade_building: ->(building_id, level) {
        building = @village.buildings.find(building_id)
        building.update!(level: level)
        @village.broadcast_building_updated(building)
        building
      },
      
      collect_resources: -> {
        resources = @village.collect_all_resources
        @village.broadcast_resource_update
        resources
      }
    }
  end
  
  def execute(command_name, *args)
    command = commands[command_name]
    raise ArgumentError, "Unknown command: #{command_name}" unless command
    
    command.call(*args)
  end
end

# Usage
commander = VillageCommandService.new(village)
building = commander.execute(:add_building, 'house', [2, 3])
resources = commander.execute(:collect_resources)
```

**What this does:** Creates a hash of named commands (procs) that can be executed dynamically. Each command encapsulates both the operation and any side effects like broadcasting updates.

**Why it's useful:**
- **Dynamic execution:** Commands can be selected and executed based on user input or game state
- **Extensibility:** New commands can be added without modifying the execution logic
- **Consistency:** All commands follow the same pattern and interface
- **Undo capability:** Commands can be designed to return data needed for reversal

**Trade-offs:**
- ✅ **Pros:** Flexible, extensible, consistent interface, good for undo systems
- ❌ **Cons:** Commands are defined at instance creation time, harder to add per-command validation or authorization

## Application Service Pattern

### Centralized Service Registry

The Application Service pattern provides a centralized way to manage and execute services across your application. This creates a unified interface for service discovery and execution while adding cross-cutting concerns like logging and hooks.

```ruby
# app/services/application_service.rb
class ApplicationService
  include ServiceCallable
  
  # Registry of all available services
  def self.registry
    @registry ||= {}
  end
  
  def self.register(name, service_class)
    registry[name] = service_class
  end
  
  def self.find_service(name)
    registry[name] || raise(ArgumentError, "Service '#{name}' not registered")
  end
  
  def self.call_service(name, *args)
    service_class = find_service(name)
    service_class.call(*args)
  end
  
  # Service lifecycle hooks
  def self.before_call(*methods)
    @before_hooks = methods
  end
  
  def self.after_call(*methods)
    @after_hooks = methods
  end
  
  private
  
  def run_before_hooks
    self.class.instance_variable_get(:@before_hooks)&.each do |hook|
      send(hook)
    end
  end
  
  def run_after_hooks
    self.class.instance_variable_get(:@after_hooks)&.each do |hook|
      send(hook)
    end
  end
end

# Register services
ApplicationService.register(:village_update, VillageUpdateService)
ApplicationService.register(:resource_production, ResourceProductionService)
ApplicationService.register(:building_construction, BuildingConstructionService)

# Usage
result = ApplicationService.call_service(:village_update, village, params)
```

**What this does:** Creates a central registry where all services are registered by name, providing a unified way to discover and execute services. It also adds lifecycle hooks that run before and after service execution.

**Why it's useful:**
- **Service discovery:** Easy to find and execute services by name without hard-coding class references
- **Cross-cutting concerns:** Hooks allow adding logging, monitoring, or authentication to all services
- **Configuration:** Services can be swapped or configured at runtime
- **Documentation:** The registry serves as a catalog of all available services

**Trade-offs:**
- ✅ **Pros:** Centralized management, cross-cutting concerns, service discovery, runtime configuration
- ❌ **Cons:** Additional complexity, indirection makes code harder to follow, registry must be maintained

### Service Composition Pattern

Service composition allows you to build complex operations by orchestrating multiple smaller services. This promotes reusability and makes complex workflows more manageable.

```ruby
class CompositeVillageService < ApplicationService
  def initialize(village)
    @village = village
  end
  
  def call
    run_before_hooks
    
    result = compose_services([
      ResourceProductionService.new(@village),
      BuildingMaintenanceService.new(@village),
      PopulationUpdateService.new(@village),
      EventProcessingService.new(@village)
    ])
    
    run_after_hooks
    result
  end
  
  private
  
  def compose_services(services)
    results = []
    
    services.each do |service|
      begin
        result = service.call
        results << result
      rescue => e
        handle_service_error(service.class.name, e)
        results << ServiceResult.failure(e.message)
      end
    end
    
    ServiceResult.new(success: results.all?(&:success?), data: results)
  end
  
  def handle_service_error(service_name, error)
    Rails.logger.error "Service #{service_name} failed: #{error.message}"
    ErrorTracker.report(error, service: service_name, village: @village.id)
  end
end
```

**What this does:** Orchestrates multiple related services in sequence, collecting their results and handling errors gracefully. Each service operates independently, but the composite service manages the overall workflow.

**Why it's useful:**
- **Reusability:** Individual services can be used independently or in other compositions
- **Error isolation:** One service failure doesn't crash the entire operation
- **Monitoring:** Easy to track which services succeed or fail
- **Maintainability:** Complex operations are broken into manageable pieces

**Trade-offs:**
- ✅ **Pros:** Modular, reusable components, good error handling, easy to test individual pieces
- ❌ **Cons:** Can become complex with many services, ordering dependencies must be managed carefully

## OpenStruct as Service Output

### Result Object Pattern with OpenStruct

Using OpenStruct for service results provides a flexible way to return structured data without defining custom classes. This pattern balances simplicity with the need for structured return values.

```ruby
# Simple result with OpenStruct
class VillageUpdateService
  def call
    begin
      update_village
      broadcast_changes
      
      OpenStruct.new(
        success: true,
        village: @village,
        resources_updated: @resources_updated,
        buildings_updated: @buildings_updated,
        message: "Village updated successfully"
      )
    rescue => e
      OpenStruct.new(
        success: false,
        error: e,
        message: e.message,
        village: @village
      )
    end
  end
end

# Usage
result = VillageUpdateService.new(village).call

if result.success
  puts "Updated #{result.resources_updated.count} resources"
  puts "Updated #{result.buildings_updated.count} buildings"
else
  puts "Error: #{result.message}"
end
```

**What this does:** Returns an OpenStruct object that can be accessed like a regular object with dot notation, but is dynamically created with the specified attributes.

**Why it's useful:**
- **Flexibility:** No need to define custom result classes for every service
- **Readability:** Callers can access results with natural dot notation
- **Quick development:** Fast to implement without ceremony of custom classes
- **Structured data:** More organized than returning hashes or arrays

**Trade-offs:**
- ✅ **Pros:** Fast to implement, flexible, readable access pattern
- ❌ **Cons:** No compile-time checking, easy to make typos, less explicit than custom classes

### Enhanced Result Object

For more sophisticated applications, extending OpenStruct provides additional functionality like method chaining and factory methods:

```ruby
class ServiceResult < OpenStruct
  def initialize(success:, **attributes)
    super(success: success, **attributes)
  end
  
  def success?
    success
  end
  
  def failure?
    !success?
  end
  
  def self.success(**attributes)
    new(success: true, **attributes)
  end
  
  def self.failure(**attributes)
    new(success: false, **attributes)
  end
  
  def on_success
    yield(self) if success?
    self
  end
  
  def on_failure
    yield(self) if failure?
    self
  end
end

# Usage with chaining
class VillageResourceService
  def call
    if can_produce_resources?
      resources = produce_resources
      ServiceResult.success(
        resources: resources,
        amount: resources.sum(&:amount),
        types: resources.map(&:type)
      )
    else
      ServiceResult.failure(
        error: :insufficient_buildings,
        message: "No buildings capable of producing resources"
      )
    end
  end
end

# Chained usage
VillageResourceService.new(village).call
  .on_success { |result| broadcast_resource_update(result.resources) }
  .on_failure { |result| log_production_failure(result.error) }
```

**What this does:** Extends OpenStruct with convenience methods for success/failure checking and method chaining. The `on_success` and `on_failure` methods allow functional-style result handling.

**Why it's useful:**
- **Method chaining:** Enables elegant handling of different result states
- **Factory methods:** `success` and `failure` class methods provide clear result creation
- **Consistent interface:** All services can use the same result object pattern
- **Functional style:** Supports functional programming patterns for result handling

**Trade-offs:**
- ✅ **Pros:** Elegant API, consistent across services, supports functional patterns
- ❌ **Cons:** More complex than simple OpenStruct, requires team adoption of the pattern

## Namespacing Service Objects

### Domain-Driven Design Namespacing

Organizing services by domain creates clear boundaries and improves maintainability as applications grow. This approach mirrors Domain-Driven Design principles by grouping related functionality together.

```ruby
# app/services/villages/
module Villages
  class CreationService < ApplicationService
    def initialize(user, village_params)
      @user = user
      @village_params = village_params
    end
    
    def call
      create_village
      setup_initial_resources
      create_starting_buildings
      
      ServiceResult.success(village: @village)
    end
  end
  
  class UpdateService < ApplicationService
    # Implementation
  end
  
  class DestructionService < ApplicationService
    # Implementation
  end
end

# app/services/buildings/
module Buildings
  class ConstructionService < ApplicationService
    # Implementation
  end
  
  class UpgradeService < ApplicationService
    # Implementation
  end
  
  class DestructionService < ApplicationService
    # Implementation
  end
end

# app/services/resources/
module Resources
  class ProductionService < ApplicationService
    # Implementation
  end
  
  class ConsumptionService < ApplicationService
    # Implementation
  end
  
  class ExchangeService < ApplicationService
    # Implementation
  end
end
```

**What this does:** Groups related services into domain-specific modules, creating clear boundaries between different areas of functionality. Each domain becomes its own namespace with related operations.

**Why it's useful:**
- **Domain clarity:** Easy to understand which services belong to which business domain
- **Scalability:** New developers can quickly find relevant services
- **Naming conflicts:** Prevents services with similar names from colliding
- **Modularity:** Domains can be developed and tested independently

**Trade-offs:**
- ✅ **Pros:** Clear organization, prevents naming conflicts, scales well, aligns with business domains
- ❌ **Cons:** Longer class names, deeper directory structure, requires discipline to maintain boundaries

### Feature-Based Namespacing

An alternative approach organizes services by application features rather than domain entities. This can be useful for applications where features cross multiple domains.

```ruby
# app/services/game_mechanics/
module GameMechanics
  class TimeProgressionService < ApplicationService
    def initialize(game_state)
      @game_state = game_state
    end
    
    def call
      advance_time
      trigger_events
      update_resources
      
      ServiceResult.success(
        time_advanced: @time_advanced,
        events_triggered: @events_triggered
      )
    end
  end
  
  class EventTriggerService < ApplicationService
    # Implementation
  end
end

# app/services/user_interface/
module UserInterface
  class NotificationService < ApplicationService
    # Implementation
  end
  
  class BroadcastService < ApplicationService
    # Implementation
  end
end
```

**What this does:** Groups services by application features that might span multiple domains. For example, `GameMechanics` includes services that work with villages, buildings, and resources together.

**Why it's useful:**
- **Feature coherence:** Services that work together are grouped together
- **Cross-domain operations:** Natural home for services that don't fit in a single domain
- **User story alignment:** Organization matches how features are developed and tested
- **Team structure:** Can align with how development teams are organized

**Trade-offs:**
- ✅ **Pros:** Aligns with feature development, good for cross-domain operations
- ❌ **Cons:** Less clear than domain boundaries, can lead to large namespaces, domain concepts may be scattered

## Making Service Objects Idempotent

### Idempotency for Background Job Safety

Idempotency is crucial when services are called from background jobs, which may be retried or run multiple times due to failures or infrastructure issues. An idempotent operation produces the same result regardless of how many times it's executed.

```ruby
class IdempotentResourceProductionService < ApplicationService
  def initialize(village_building_id)
    @village_building_id = village_building_id
    @village_building = VillageBuilding.find(@village_building_id)
  end
  
  def call
    # Use database-level idempotency key
    idempotency_key = generate_idempotency_key
    
    # Check if this operation was already performed
    existing_operation = Operation.find_by(idempotency_key: idempotency_key)
    return existing_operation.result if existing_operation&.completed?
    
    # Perform the operation
    operation = Operation.create!(
      idempotency_key: idempotency_key,
      status: 'processing',
      village_building_id: @village_building_id
    )
    
    begin
      result = perform_production
      operation.update!(status: 'completed', result: result.to_h)
      result
    rescue => e
      operation.update!(status: 'failed', error: e.message)
      raise
    end
  end
  
  private
  
  def generate_idempotency_key
    # Include timestamp rounded to production interval to ensure
    # multiple calls within the same interval are idempotent
    time_slot = (Time.current.to_i / production_interval).floor
    "resource_production:#{@village_building_id}:#{time_slot}"
  end
  
  def production_interval
    @village_building.building.production_interval || 300 # 5 minutes default
  end
  
  def perform_production
    # Actual production logic here
    resources = produce_resources_from_building
    
    ServiceResult.success(
      resources: resources,
      produced_at: Time.current
    )
  end
end
```

**What this does:** Uses a database record to track whether an operation has already been performed within a specific time window. The idempotency key combines the building ID with a time slot, ensuring operations are only performed once per interval.

**Why it's crucial for background jobs:**
- **Retry safety:** Jobs can be safely retried without duplicating effects
- **Failure recovery:** System can recover from failures without inconsistent state
- **Concurrency protection:** Multiple workers can't accidentally duplicate work
- **Audit trail:** Operations are recorded for debugging and monitoring

**Trade-offs:**
- ✅ **Pros:** Bulletproof retry safety, excellent for background jobs, provides audit trail
- ❌ **Cons:** Additional database complexity, requires careful key design, performance overhead

### Conditional Idempotency

Not all operations should be idempotent. Some services need to handle different types of operations with varying idempotency requirements:

```ruby
class ConditionalIdempotentService < ApplicationService
  def initialize(village, action_type, params = {})
    @village = village
    @action_type = action_type
    @params = params
  end
  
  def call
    case @action_type
    when :resource_production
      idempotent_resource_production
    when :building_construction
      idempotent_building_construction
    when :user_notification
      # Notifications should NOT be idempotent
      send_notification
    else
      raise ArgumentError, "Unknown action type: #{@action_type}"
    end
  end
  
  private
  
  def idempotent_resource_production
    key = "village:#{@village.id}:resources:#{Date.current}"
    Rails.cache.fetch(key, expires_in: 1.hour) do
      perform_resource_production
    end
  end
  
  def idempotent_building_construction
    # Use database constraints for idempotency
    building = @village.buildings.find_or_create_by(
      building_type: @params[:building_type],
      position_x: @params[:x],
      position_y: @params[:y]
    ) do |b|
      b.level = 1
      b.constructed_at = Time.current
    end
    
    ServiceResult.success(building: building, created: building.previously_new_record?)
  end
  
  def send_notification
    # Non-idempotent operation
    NotificationService.new(@village.user, @params[:message]).call
  end
end
```

**What this does:** Demonstrates different idempotency strategies based on the operation type. Resource production uses caching, building construction uses database constraints, and notifications intentionally avoid idempotency.

**Why different strategies matter:**
- **Resource production:** Should be idempotent within time windows to prevent duplicate resources
- **Building construction:** Should prevent duplicate buildings at the same location
- **Notifications:** Should NOT be idempotent as users might need to receive the same message multiple times

**Trade-offs:**
- ✅ **Pros:** Flexible approach, matches business requirements, efficient implementations
- ❌ **Cons:** More complex logic, requires careful analysis of each operation type

### Distributed Idempotency with Redis

For applications running across multiple servers, Redis provides distributed coordination for idempotency:

```ruby
class DistributedIdempotentService < ApplicationService
  def initialize(operation_id, params)
    @operation_id = operation_id
    @params = params
  end
  
  def call
    # Try to acquire distributed lock
    redis_key = "idempotent_operation:#{@operation_id}"
    
    Redis.current.set(redis_key, "processing", nx: true, ex: 300) do
      begin
        result = perform_operation
        
        # Store result for future identical requests
        Redis.current.setex(
          "idempotent_result:#{@operation_id}",
          3600, # 1 hour
          result.to_json
        )
        
        result
      ensure
        Redis.current.del(redis_key)
      end
    end || get_cached_result
  end
  
  private
  
  def get_cached_result
    cached = Redis.current.get("idempotent_result:#{@operation_id}")
    cached ? ServiceResult.from_json(cached) : ServiceResult.failure(error: "Operation already in progress")
  end
  
  def perform_operation
    # Actual operation logic
    ServiceResult.success(data: "Operation completed", operation_id: @operation_id)
  end
end
```

**What this does:** Uses Redis to coordinate idempotency across multiple application instances. It attempts to acquire a distributed lock, performs the operation if successful, and caches the result for future identical requests.

**Why distributed coordination is important:**
- **Multi-server deployments:** Prevents duplicate operations across different servers
- **Horizontal scaling:** Works correctly as you add more application instances
- **Race condition prevention:** Atomic Redis operations prevent concurrent execution
- **Result caching:** Subsequent identical requests get cached results immediately

**Trade-offs:**
- ✅ **Pros:** Works across multiple servers, atomic operations, fast result retrieval
- ❌ **Cons:** Requires Redis infrastructure, network dependency, more complex debugging

---

This comprehensive exploration of advanced service object patterns provides the tools needed to build sophisticated, maintainable service layers in Rails applications. Each pattern addresses specific challenges while introducing its own trade-offs, allowing you to choose the right approach for your specific requirements.
