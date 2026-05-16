module Api
  module V1
    class TherapistMessagesController < BaseController
      rate_limit to: 5, within: 1.hour,
        by: -> { "#{params[:unique_id]}:#{request.remote_ip}" },
        with: -> { render json: { error: "Too many messages. Please try again later." }, status: :too_many_requests }

      def create
        therapist = Therapist.includes(:user).find_by!(unique_id: params[:unique_id])
        return render_not_found unless therapist.can_receive_public_messages?

        verify_turnstile!

        message = therapist.therapist_messages.create(message_params)
        return render_errors(message) unless message.persisted?

        enqueue_delivery(message)
      rescue ActiveRecord::RecordNotFound
        render_not_found
      rescue TurnstileVerifier::VerificationError
        render json: { error: "Security check failed. Please try again." }, status: :unprocessable_entity
      rescue TurnstileVerifier::ConfigurationError => e
        Rails.logger.error("event=turnstile.config_error error=#{e.class}")
        render json: { error: "Message delivery is not available right now." }, status: :service_unavailable
      end

      private

      def verify_turnstile!
        TurnstileVerifier.verify!(
          token: turnstile_token,
          remote_ip: request.remote_ip
        )
      end

      def enqueue_delivery(message)
        message.enqueue_delivery!
        render json: { id: message.id, status: message.delivery_status }, status: :accepted
      rescue StandardError => e
        message.mark_failed!(e)
        Notifier.notify(
          :email_service,
          "Therapist message saved but delivery was not queued. " \
          "therapist_message_id=#{message.id} error=#{e.class}"
        )
        render json: { error: "Message saved, but delivery is delayed." }, status: :service_unavailable
      end

      def render_errors(message)
        render json: { errors: message.errors.to_hash(true) }, status: :unprocessable_entity
      end

      def render_not_found
        render json: { error: "Therapist not found." }, status: :not_found
      end

      def message_params
        params.require(:message).permit(
          :sender_name,
          :sender_email,
          :sender_phone,
          :body,
          :page_url
        )
      end

      def turnstile_token
        params[:turnstile_token].presence ||
          params[:"cf-turnstile-response"].presence ||
          params.dig(:message, :turnstile_token).presence
      end
    end
  end
end
