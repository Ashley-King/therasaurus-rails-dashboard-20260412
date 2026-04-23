class Avo::Actions::RunR2OrphanCleanup < Avo::BaseAction
  self.name = "Run R2 orphan cleanup"
  self.message = "Enqueue R2OrphanCleanupJob now? Check logs for results."
  self.confirm_button_label = "Enqueue job"
  self.standalone = true

  def handle(**)
    R2OrphanCleanupJob.perform_later
    succeed "R2 orphan cleanup job enqueued. Watch the logs for output."
  end
end
