class PracticePaymentMethod < ApplicationRecord
  belongs_to :therapist
  belongs_to :payment_method
end
