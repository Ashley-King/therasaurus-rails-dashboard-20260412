# Post-checkout landing page. Stripe's success_url points here.
#
# Intentionally inert: it does NOT read the `session_id` URL param to
# decide membership state. Membership state is set only when the Stripe
# webhook is processed. The page tolerates the case where the redirect
# lands before the webhook does.
class TrialStartedController < ApplicationController
  include Authentication

  layout "auth"

  before_action :require_auth
  before_action :require_profile

  # GET /trial-started
  def show
  end
end
