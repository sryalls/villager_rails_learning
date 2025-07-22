# Coordination concern for jobs
module DistributedCoordination
  extend ActiveSupport::Concern

  def coordinator
    @coordinator ||= DistributedCoordinator.new
  end

  def with_coordination_lock(key, &block)
    coordinator.with_distributed_lock("job_coordination:#{key}", &block)
  end

  def attempt_leadership(group)
    coordinator.elect_leader("job_leader:#{group}")
  end

  def broadcast_to_instances(channel, message)
    coordinator.send_coordination_message(channel, message.merge(
      sender: instance_identifier,
      timestamp: Time.current.to_f
    ))
  end

  private

  def instance_identifier
    "#{Socket.gethostname}:#{Process.pid}"
  end
end
