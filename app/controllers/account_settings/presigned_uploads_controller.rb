module AccountSettings
  class PresignedUploadsController < BaseController
    ALLOWED_TYPES = %w[image/jpeg image/png].freeze
    MAX_SIZE = 5.megabytes

    def create
      content_type = params[:content_type]
      file_size = params[:file_size].to_i

      unless ALLOWED_TYPES.include?(content_type)
        return render json: { error: "File type not allowed. Use JPEG or PNG." }, status: :unprocessable_entity
      end

      if file_size > MAX_SIZE
        return render json: { error: "File too large. Maximum size is 5 MB." }, status: :unprocessable_entity
      end

      extension = Rack::Mime::MIME_TYPES.invert[content_type]
      key = "profiles/#{therapist.id}/#{Time.current.to_i}-#{SecureRandom.hex(3)}#{extension}"

      presigned_url = Aws::S3::Presigner.new(client: r2_client).presigned_url(
        :put_object,
        bucket: fetch_credential!(:R2_HEADSHOTS_BUCKET_NAME),
        key: key,
        content_type: content_type,
        expires_in: 300
      )

      # Return only the R2 object key. The public URL is built on demand
      # in Therapist#practice_image_url so we can change bucket / CDN /
      # env without a data migration.
      render json: { presigned_url: presigned_url, key: key }
    rescue KeyError => e
      Rails.logger.error("R2 upload configuration error: #{e.message}")
      render json: { error: "Profile photo uploads are not configured yet." }, status: :service_unavailable
    end

    private

    def r2_client
      @r2_client ||= Aws::S3::Client.new(
        region: "auto",
        endpoint: fetch_credential!(:R2_ENDPOINT),
        credentials: Aws::Credentials.new(
          fetch_credential!(:R2_ACCESS_KEY_ID),
          fetch_credential!(:R2_SECRET_ACCESS_KEY)
        ),
        token_provider: nil
      )
    end

    def fetch_credential!(key)
      value = Rails.application.credentials.fetch(key)
      raise KeyError, "#{key} is blank" if value.blank?

      value
    end
  end
end
