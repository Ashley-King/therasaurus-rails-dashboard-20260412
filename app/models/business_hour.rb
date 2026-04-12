class BusinessHour < ApplicationRecord
  belongs_to :therapist

  DAYS = { sunday: 0, monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5, saturday: 6 }.freeze

  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :open_time, :close_time, presence: true
  validate :close_time_after_open_time

  scope :ordered, -> { order(:day_of_week, :open_time) }

  def day_name
    DAYS.key(day_of_week)&.to_s&.capitalize
  end

  private

  def close_time_after_open_time
    return unless open_time && close_time
    errors.add(:close_time, "must be after open time") if close_time <= open_time
  end
end
