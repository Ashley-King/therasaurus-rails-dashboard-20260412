class Avo::Actions::RetryTherapistMessageDelivery < Avo::BaseAction
  self.name = "Retry message delivery"
  self.message = "Queue delivery again for the selected therapist messages?"
  self.confirm_button_label = "Retry delivery"

  def handle(query:, **)
    count = 0

    query.each do |message|
      count += 1 if message.enqueue_delivery!
    end

    succeed "#{count} message delivery #{'job'.pluralize(count)} queued."
  end
end
