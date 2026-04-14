module AccountSettings
  class PresignedUploadsController < BaseController
    ALLOWED_TYPES = %w[image/jpeg image/png image/webp].freeze
    MAX_SIZE = 10.megabytes

    def create
      content_type = params[:content_type]
      file_size = params[:file_size].to_i

      unless ALLOWED_TYPES.include?(content_type)
        return render json: { error: "File type not allowed. Use JPEG, PNG, or WebP." }, status: :unprocessable_entity
      end

      if file_size > MAX_SIZE
        return render json: { error: "File too large. Maximum size is 10 MB." }, status: :unprocessable_entity
      end

      extension = Rack::Mime::MIME_TYPES.invert[content_type]
      key = "profiles/#{therapist.id}/#{Time.current.to_i}-#{SecureRandom.hex(3)}#{extension}"

      presigned_url = Aws::S3::Presigner.new(client: r2_client).presigned_url(
        :put_object,
        bucket: Rails.application.credentials.R2_HEADSHOTS_BUCKET_NAME,
        key: key,
        content_type: content_type,
        expires_in: 300
      )

      public_url = "#{Rails.application.credentials.R2_PUBLIC_URL}/#{key}"

      render json: { presigned_url: presigned_url, public_url: public_url }
    end

    private

    def r2_client
      @r2_client ||= Aws::S3::Client.new(
        region: "auto",
        endpoint: Rails.application.credentials.R2_ENDPOINT,
        credentials: Aws::Credentials.new(
          Rails.application.credentials.R2_ACCESS_KEY_ID,
          Rails.application.credentials.R2_SECRET_ACCESS_KEY
        )
      )
    end
  end
end
