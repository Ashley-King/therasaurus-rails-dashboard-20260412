class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Surface the authenticated user id (never email) to lograge custom_options.
  # Only call current_user if the Authentication concern is included on the
  # controller; otherwise skip silently.
  def append_info_to_payload(payload)
    super
    payload[:user_id] = current_user&.id if respond_to?(:current_user, true)
  end
end
