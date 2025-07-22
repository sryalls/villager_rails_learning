# Implementation Examples from Key Authors

This document contains practical implementation examples from the most influential Service Objects articles.

## Amin Shah Gilani's Approach (Toptal)

### Base Service Class

From "Rails Service Objects Tutorial":

```ruby
# app/services/application_service.rb
class ApplicationService
  def self.call(*args, &block)
    new(*args, &block).call
  end
end
```

**Key Benefits**:
- Enables `ServiceName.call(args)` syntax
- Consistent interface across all services
- Reduces boilerplate code

### Example Implementation: Tweet Creator

```ruby
# app/services/twitter_manager/tweet_creator.rb
module TwitterManager
  class TweetCreator < ApplicationService
    attr_reader :message
    
    def initialize(message)
      @message = message
    end

    def call
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
        config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
        config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
        config.access_token_secret = ENV['TWITTER_ACCESS_SECRET']
      end
      
      client.update(message)
    rescue Twitter::Error => e
      Rails.logger.error "Tweet creation failed: #{e.message}"
      false
    else
      true
    end
  end
end
```

**Usage**:
```ruby
# In controller
def create
  if TwitterManager::TweetCreator.call(params[:message])
    redirect_to root_path, notice: 'Tweet sent successfully!'
  else
    redirect_to root_path, alert: 'Failed to send tweet'
  end
end
```

### Example Implementation: Database Operations

```ruby
# app/services/money_manager/currency_exchanger.rb
module MoneyManager
  class CurrencyExchanger < ApplicationService
    def initialize(user_account:, amount:, from_currency:, to_currency:)
      @user_account = user_account
      @amount = amount
      @from_currency = from_currency
      @to_currency = to_currency
    end

    def call
      ActiveRecord::Base.transaction do
        # Transfer original currency to exchange account
        outgoing_tx = CurrencyTransferrer.call(
          from: @user_account,
          to: exchange_account,
          amount: @amount,
          currency: @from_currency
        )

        # Get exchange rate
        rate = ExchangeRateGetter.call(
          from: @from_currency,
          to: @to_currency
        )

        # Transfer new currency back to user
        incoming_tx = CurrencyTransferrer.call(
          from: exchange_account,
          to: @user_account,
          amount: @amount * rate,
          currency: @to_currency
        )

        # Record the exchange
        ExchangeRecorder.call(
          outgoing_tx: outgoing_tx,
          incoming_tx: incoming_tx
        )
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Currency exchange failed: #{e.message}"
      false
    end

    private

    def exchange_account
      @exchange_account ||= Account.find_by(type: 'exchange')
    end
  end
end
```

### Gilani's Four Rules

1. **Only One Public Method per Service Object**
2. **Name Service Objects Like Dumb Roles at a Company**
3. **Don't Create Generic Objects to Perform Multiple Actions**
4. **Handle Exceptions Inside the Service Object**

## Nicholaus Haskins' Approach (AppSignal)

### OpenStruct Response Pattern

From "Using Service Objects in Ruby on Rails":

```ruby
# Base pattern for all services
def call
  result = perform_operation
  OpenStruct.new({ success?: true, payload: result })
rescue StandardError => e
  OpenStruct.new({ success?: false, error: e })
end
```

### Example Implementation: Stripe Integration

```ruby
# app/services/stripe_services/create_subscription.rb
module StripeServices
  class CreateSubscription < ApplicationService
    def initialize(params)
      @subscription_params = params[:subscription_params]
      @stripe_account = params[:stripe_account]
      @stripe_secret_key = params[:stripe_secret_key] || default_stripe_key
    end

    def call
      subscription = Stripe::Subscription.create(
        @subscription_params, 
        account_params
      )
      
      OpenStruct.new({ success?: true, payload: subscription })
    rescue Stripe::StripeError => e
      OpenStruct.new({ success?: false, error: e })
    end

    private

    attr_reader :stripe_account, :stripe_secret_key

    def account_params
      {
        api_key: stripe_secret_key,
        stripe_account: stripe_account,
        stripe_version: ENV['STRIPE_API_VERSION']
      }
    end

    def default_stripe_key
      Rails.env.production? ? ENV['STRIPE_LIVE_SECRET_KEY'] : ENV['STRIPE_TEST_SECRET_KEY']
    end
  end
end
```

### Example Implementation: Application Logic Service

```ruby
# app/services/app_services/subscription_service.rb
module AppServices
  class SubscriptionService < ApplicationService
    def initialize(params)
      @subscription = params[:subscription_params][:subscription]
      @token = params[:subscription_params][:token]
      @plan = @subscription.subscription_plan
      @user = @subscription.user
    end

    def call
      # First, create or find customer
      customer = AppServices::CustomerService.new({
        customer_params: {
          customer: @user,
          token: @token
        }
      }).call

      return handle_error(customer&.error) unless customer&.success?

      # Then create subscription
      subscription = StripeServices::CreateSubscription.new({
        subscription_params: {
          customer: customer.payload,
          items: [subscription_items],
          expand: ['latest_invoice.payment_intent']
        }
      }).call

      if subscription&.success?
        update_local_subscription(subscription.payload)
        OpenStruct.new({ success?: true, payload: subscription.payload })
      else
        handle_error(subscription&.error)
      end
    end

    private

    attr_reader :plan, :subscription, :user

    def subscription_items
      [{ plan: plan.stripe_id }]
    end

    def update_local_subscription(stripe_subscription)
      @subscription.update_attributes(
        status: 'active',
        stripe_id: stripe_subscription.id,
        expiration: Time.at(stripe_subscription.current_period_end).to_datetime
      )
    end

    def handle_error(error)
      OpenStruct.new({ success?: false, error: error })
    end
  end
end
```

### Controller Usage Pattern

```ruby
# app/controllers/subscriptions_controller.rb
class SubscriptionsController < ApplicationController
  def create
    @subscription = Subscription.new(subscription_params)

    if @subscription.save
      result = AppServices::SubscriptionService.new({
        subscription_params: {
          subscription: @subscription,
          coupon: params[:coupon],
          token: params[:stripeToken]
        }
      }).call

      if result&.success?
        sign_in @subscription.user
        redirect_to subscribe_welcome_path, 
                   success: 'Subscription was successfully created.'
      else
        @subscription.destroy
        redirect_to subscribe_path, 
                   danger: "Subscription created, but there was a problem with the vendor."
      end
    else
      redirect_to subscribe_path, 
                 danger: "Error creating subscription."
    end
  end

  private

  def subscription_params
    params.require(:subscription).permit(:plan_id, :user_id)
  end
end
```

## Alternative Patterns and Variations

### Result Object Pattern

Instead of OpenStruct, use a custom result class:

```ruby
class ServiceResult
  attr_reader :success, :data, :errors

  def initialize(success:, data: nil, errors: [])
    @success = success
    @data = data
    @errors = Array(errors)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def error_messages
    @errors.map(&:to_s)
  end
end

# Usage in service
def call
  result = perform_operation
  ServiceResult.new(success: true, data: result)
rescue StandardError => e
  ServiceResult.new(success: false, errors: [e.message])
end
```

### Enum Response Pattern

For services with multiple possible outcomes:

```ruby
class ExchangeRecorder < ApplicationService
  RETURNS = [
    SUCCESS = :success,
    FAILURE = :failure,
    PARTIAL_SUCCESS = :partial_success
  ].freeze

  def call
    result = perform_exchange
    
    return SUCCESS if result.complete?
    return FAILURE if result.failed?
    PARTIAL_SUCCESS
  end
end

# Usage
case ExchangeRecorder.call
when ExchangeRecorder::SUCCESS
  handle_success
when ExchangeRecorder::FAILURE
  handle_failure
when ExchangeRecorder::PARTIAL_SUCCESS
  handle_partial_success
end
```

### Dry-rb Monads Integration

Using dry-rb for functional result handling:

```ruby
require 'dry/monads'

class ModernService
  include Dry::Monads[:result]

  def call
    result = perform_operation
    Success(result)
  rescue StandardError => e
    Failure(e.message)
  end

  private

  def perform_operation
    # Business logic here
  end
end

# Usage
result = ModernService.new.call

result.fmap { |data| puts "Success: #{data}" }
      .or    { |error| puts "Error: #{error}" }
```

## Testing Patterns

### RSpec Testing Examples

```ruby
# spec/services/twitter_manager/tweet_creator_spec.rb
RSpec.describe TwitterManager::TweetCreator do
  subject(:service) { described_class.new(message) }
  
  let(:message) { "Hello World!" }
  let(:twitter_client) { instance_double(Twitter::REST::Client) }

  before do
    allow(Twitter::REST::Client).to receive(:new).and_return(twitter_client)
  end

  describe "#call" do
    context "when tweet is sent successfully" do
      before do
        allow(twitter_client).to receive(:update).with(message).and_return(true)
      end

      it "returns true" do
        expect(service.call).to be true
      end
    end

    context "when Twitter API fails" do
      before do
        allow(twitter_client).to receive(:update).and_raise(Twitter::Error.new("API Error"))
      end

      it "returns false" do
        expect(service.call).to be false
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Tweet creation failed/)
        service.call
      end
    end
  end
end
```

### Integration Testing

```ruby
# spec/services/app_services/subscription_service_spec.rb
RSpec.describe AppServices::SubscriptionService do
  subject(:service) { described_class.new(params) }
  
  let(:user) { create(:user) }
  let(:subscription) { create(:subscription, user: user) }
  let(:params) do
    {
      subscription_params: {
        subscription: subscription,
        token: 'stripe_token_123'
      }
    }
  end

  describe "#call" do
    context "when all external services succeed" do
      before do
        # Mock successful customer service call
        customer_result = OpenStruct.new(success?: true, payload: 'cus_123')
        allow(AppServices::CustomerService).to receive_message_chain(:new, :call)
                                          .and_return(customer_result)

        # Mock successful stripe subscription call
        subscription_result = OpenStruct.new(
          success?: true, 
          payload: double(id: 'sub_123', current_period_end: 1.month.from_now.to_i)
        )
        allow(StripeServices::CreateSubscription).to receive_message_chain(:new, :call)
                                                 .and_return(subscription_result)
      end

      it "returns success" do
        result = service.call
        expect(result.success?).to be true
      end

      it "updates the subscription record" do
        service.call
        subscription.reload
        expect(subscription.status).to eq('active')
        expect(subscription.stripe_id).to eq('sub_123')
      end
    end

    context "when customer service fails" do
      before do
        customer_result = OpenStruct.new(success?: false, error: 'Customer creation failed')
        allow(AppServices::CustomerService).to receive_message_chain(:new, :call)
                                          .and_return(customer_result)
      end

      it "returns failure" do
        result = service.call
        expect(result.success?).to be false
        expect(result.error).to eq('Customer creation failed')
      end
    end
  end
end
```

## Performance Considerations

### Service Object Caching

```ruby
class ExpensiveCalculationService < ApplicationService
  def initialize(data_set)
    @data_set = data_set
  end

  def call
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      perform_expensive_calculation
    end
  end

  private

  def cache_key
    "expensive_calculation:#{@data_set.cache_key_with_version}"
  end

  def perform_expensive_calculation
    # Complex computation here
  end
end
```

### Async Service Execution

```ruby
class AsyncEmailService < ApplicationService
  def initialize(user, template)
    @user = user
    @template = template
  end

  def call
    EmailWorker.perform_async(@user.id, @template)
  end
end

# Background job
class EmailWorker
  include Sidekiq::Worker

  def perform(user_id, template)
    user = User.find(user_id)
    EmailServices::SendNotification.call(user: user, template: template)
  end
end
```

---

*These examples demonstrate the practical implementation approaches advocated by the most influential writers on Service Objects in the Rails community.*
