class TherapistFaq < ApplicationRecord
  QUESTION_MAX = 200
  ANSWER_MAX = 1000

  belongs_to :therapist

  before_validation :strip_html

  validates :question, presence: true, length: { maximum: QUESTION_MAX }
  validates :answer, presence: true, length: { maximum: ANSWER_MAX }

  private

  def strip_html
    self.question = ActionController::Base.helpers.strip_tags(question).to_s.strip if question.present?
    self.answer = ActionController::Base.helpers.strip_tags(answer).to_s.strip if answer.present?
  end
end
