# Model
class ResourceCollection < ApplicationRecord
  belongs_to :village
  
  # TODO: Add validations for idempotency
  # TODO: Add scopes for querying collections
end
