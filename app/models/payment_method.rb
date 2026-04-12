class PaymentMethod < ApplicationRecord
  has_many :practice_payment_methods
  has_many :therapists, through: :practice_payment_methods
end
