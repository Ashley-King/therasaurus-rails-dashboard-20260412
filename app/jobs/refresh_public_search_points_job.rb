class RefreshPublicSearchPointsJob < ApplicationJob
  queue_as :default

  def perform(therapist_id)
    PublicSearchPointRefresh.call(therapist_id)
  end
end
