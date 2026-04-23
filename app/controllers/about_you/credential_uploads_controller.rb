module AboutYou
  class CredentialUploadsController < BaseController
    ALLOWED_TYPES = %w[
      application/pdf
      image/jpeg
      image/png
      image/webp
      image/heic
      image/heif
    ].freeze
    MAX_SIZE = 10.megabytes

    def create
      content_type = params[:content_type]
      file_size = params[:file_size].to_i

      unless ALLOWED_TYPES.include?(content_type)
        return render json: { error: "File type not allowed. Use PDF, JPEG, PNG, WebP, or HEIC." }, status: :unprocessable_entity
      end

      if file_size > MAX_SIZE
        return render json: { error: "File too large. Maximum size is 10 MB." }, status: :unprocessable_entity
      end

      extension = Rack::Mime::MIME_TYPES.invert[content_type] || ".bin"
      key = "credentials/#{therapist.id}/#{Time.current.to_i}-#{SecureRandom.hex(3)}#{extension}"

      presigned_url = Aws::S3::Presigner.new(client: r2_client).presigned_url(
        :put_object,
        bucket: fetch_credential!(:R2_CREDENTIALS_BUCKET_NAME),
        key: key,
        content_type: content_type,
        expires_in: 300
      )

      # The ptd-credentials bucket is private — we store only the object
      # key. Presigned GET URLs are minted on demand in the admin download
      # flow (CredentialDocumentsController). No public URL is ever stored
      # in the database.
      render json: { presigned_url: presigned_url, key: key }
    rescue KeyError => e
      Rails.logger.error("R2 credential upload configuration error: #{e.message}")
      render json: { error: "Document uploads are not configured yet." }, status: :service_unavailable
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
