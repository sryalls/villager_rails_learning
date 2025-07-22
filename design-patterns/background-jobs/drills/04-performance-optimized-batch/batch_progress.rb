# Batch progress tracking
class BatchProgress < ApplicationRecord
  belongs_to :processing_batch

  def completion_percentage
    # TODO: Calculate completion percentage
  end

  def estimated_completion_time
    # TODO: Estimate completion time based on current rate
  end

  def items_per_second
    # TODO: Calculate processing rate
  end
end
