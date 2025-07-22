class ProcessingBatch < ApplicationRecord
  has_many :batch_progresses, dependent: :destroy

  validates :name, presence: true
  validates :total_items, presence: true, numericality: { greater_than: 0 }

  enum status: { pending: 0, processing: 1, completed: 2, failed: 3 }

  def current_progress
    batch_progresses.order(:created_at).last
  end
end
