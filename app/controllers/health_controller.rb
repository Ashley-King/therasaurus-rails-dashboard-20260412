# Deep health check for uptime monitoring (Better Stack, etc.).
#
# Returns 200 when all dependencies are reachable, 503 when any are
# degraded. Never throttled, silenced from request logs.
#
# The built-in /up endpoint is a shallow liveness probe (Rails boots?).
# This endpoint checks the things that actually matter at runtime.

class HealthController < ActionController::API
  def show
    checks = {
      db: check_database,
      queue: check_queue
    }

    healthy = checks.values.all? { |c| c[:status] == "ok" }
    status = healthy ? :ok : :service_unavailable

    render json: checks.transform_values { |c| c[:status] }, status: status
  end

  private

  def check_database
    ActiveRecord::Base.connection.execute("SELECT 1")
    { status: "ok" }
  rescue StandardError => e
    { status: "error", error: e.message }
  end

  def check_queue
    SolidQueue::Process.any?
    { status: "ok" }
  rescue StandardError => e
    { status: "error", error: e.message }
  end
end
