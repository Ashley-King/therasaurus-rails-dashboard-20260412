module AccountSettings
  class MembershipsController < BaseController
    def show
    end

    # POST /account-settings/membership/portal
    # Sends the therapist to the Stripe Customer Portal where they can
    # update their card, view invoices, switch monthly→annual, or cancel.
    def portal
      processor = current_user.payment_processor
      unless processor&.processor_id?
        redirect_to start_trial_path,
                    alert: "Start your free trial first to manage billing."
        return
      end

      session = processor.billing_portal(return_url: membership_url)
      redirect_to session.url, allow_other_host: true, status: :see_other
    rescue ::Stripe::StripeError => e
      Notifier.notify(
        :stripe_errors,
        "Portal session failed for user #{current_user.id}: #{e.class}: #{e.message}"
      )
      redirect_to membership_path,
                  alert: "We couldn't open the billing portal right now. Please try again in a moment."
    end
  end
end
