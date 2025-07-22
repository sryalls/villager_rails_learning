# Model for tracking collections
class ResourceCollection < ApplicationRecord
  belongs_to :village

  validates :idempotency_key, presence: true, uniqueness: true
  validates :collection_type, presence: true
  validates :collected_at, presence: true

  # TODO: Add additional validations and methods as needed
  # Consider adding scopes, helper methods, and data validation
end
