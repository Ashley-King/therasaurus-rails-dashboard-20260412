class PracticeSpecialty < ApplicationRecord
  belongs_to :therapist
  belongs_to :specialty

  after_commit :refresh_public_search_points_later, on: [ :create, :update, :destroy ]

  private

  def refresh_public_search_points_later
    RefreshPublicSearchPointsJob.perform_later(therapist_id)
  end
end
