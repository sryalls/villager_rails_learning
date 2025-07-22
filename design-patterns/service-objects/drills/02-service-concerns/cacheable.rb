# app/services/concerns/cacheable.rb
module Cacheable
  extend ActiveSupport::Concern

  def call_with_cache(cache_key, expires_in: 1.hour)
    # TODO: Implement caching logic
    # Return cached result if available, otherwise call service and cache result
  end

  private

  def cache_key_for(*args)
    # TODO: Generate cache key from service class and arguments
  end
end
