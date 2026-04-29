class FeatureRequestsController < ApplicationController
  include Authentication
  before_action :require_auth
  before_action :require_profile

  NOTIFY_CHANNELS = {
    "specialty" => :specialties,
    "service" => :services,
    "insurance_company" => :insurance_write_in,
    "college" => :college_write_in,
    "general" => :feature_requests
  }.freeze

  def create
    @frame_id = params[:frame_id].to_s
    @feature_request = current_therapist.feature_requests.new(feature_request_params)

    if @feature_request.save
      Notifier.notify(
        NOTIFY_CHANNELS.fetch(@feature_request.kind, :feature_requests),
        notification_message(@feature_request)
      )
      render :create
    else
      render :create, status: :unprocessable_entity
    end
  end

  private

  def feature_request_params
    params.require(:feature_request).permit(:kind, :body, :page_url)
  end

  def notification_message(fr)
    page = fr.page_url.presence || "(no page)"
    body = fr.body.to_s.truncate(1500)
    "Feature request (#{fr.kind}) from therapist #{current_therapist.id}\nPage: #{page}\n\n#{body}"
  end
end
