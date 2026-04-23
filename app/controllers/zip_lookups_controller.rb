class ZipLookupsController < ApplicationController
  include Authentication
  before_action :require_auth

  MAX_RESULTS = 10
  MIN_QUERY_LENGTH = 2

  def search
    query = params[:q].to_s.strip

    results = if query.match?(/\A\d{#{MIN_QUERY_LENGTH},5}\z/)
      ZipLookup.prefix_search(query, limit: MAX_RESULTS)
    else
      []
    end

    response.headers["Cache-Control"] = "private, max-age=60"
    render json: results.map { |r|
      { zip: r["zip"], city: r["city"], state: r["state_id"], lat: r["lat"], lng: r["lng"] }
    }
  end
end
