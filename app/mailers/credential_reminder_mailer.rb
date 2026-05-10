class CredentialReminderMailer < ApplicationMailer
  def expiration_month
    set_credential

    mail(
      to: @user.email,
      subject: "Your TheraSaurus credential expires this month"
    )
  end

  def expiration_week
    set_credential

    mail(
      to: @user.email,
      subject: "Your TheraSaurus credential expires in 7 days"
    )
  end

  def grace_started
    set_credential

    mail(
      to: @user.email,
      subject: "Your TheraSaurus credential renewal grace period has started"
    )
  end

  def expired
    set_credential

    mail(
      to: @user.email,
      subject: "Your TheraSaurus credential has expired"
    )
  end

  private

  def set_credential
    @credential = params.fetch(:credential)
    @therapist = @credential.therapist
    @user = @therapist.user
    @expiration_date = @credential.expiration_date
    @grace_expires_at = @credential.grace_expires_at ||
      (@expiration_date.end_of_day + UserCredential::GRACE_PERIOD if @expiration_date)
    @grace_expires_date = @grace_expires_at&.to_date
  end
end
