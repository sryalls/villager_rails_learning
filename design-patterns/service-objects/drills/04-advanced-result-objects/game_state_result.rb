# Enhanced ServiceResult class
class GameStateResult < OpenStruct
  def initialize(success:, **attributes)
    super(success: success, **attributes)
  end

  def success?
    success
  end

  def failure?
    !success?
  end

  def partial_success?
    # TODO: Implement logic for partial success
    # (some operations succeeded, others failed)
  end

  def on_success
    yield(self) if success?
    self
  end

  def on_failure
    yield(self) if failure?
    self
  end

  def on_partial_success
    yield(self) if partial_success?
    self
  end

  def summary
    # TODO: Return a human-readable summary of the operation
  end
end
