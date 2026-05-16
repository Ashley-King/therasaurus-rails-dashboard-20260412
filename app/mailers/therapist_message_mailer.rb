class TherapistMessageMailer < ApplicationMailer
  def new_message
    @message = params.fetch(:message)
    @therapist = @message.therapist
    @user = @therapist.user

    mail(
      to: @user.email,
      reply_to: @message.sender_email,
      subject: "New client message from #{@message.sender_name}"
    )
  end
end
