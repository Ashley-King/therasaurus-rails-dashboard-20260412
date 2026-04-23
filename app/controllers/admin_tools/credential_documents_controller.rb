module AdminTools
  # Admin-only. Mints a short-lived presigned GET URL for a credential
  # document stored in the private `ptd-credentials` R2 bucket and
  # redirects the browser to it so the admin can open/download the file.
  #
  # The bucket is not public — there is no other path to the file. The
  # signed URL expires in 5 minutes and is not indexable.
  class CredentialDocumentsController < ApplicationController
    include Authentication

    before_action :require_auth
    before_action :require_admin

    PRESIGN_EXPIRES_IN = 300 # 5 minutes

    def show
      credential = UserCredential.find(params[:id])

      if credential.credential_document.blank?
        return redirect_back_or_to "/admin", alert: "No credential document uploaded."
      end

      url = Aws::S3::Presigner.new(client: r2_client).presigned_url(
        :get_object,
        bucket: fetch_credential!(:R2_CREDENTIALS_BUCKET_NAME),
        key: credential.credential_document,
        expires_in: PRESIGN_EXPIRES_IN,
        response_content_disposition: content_disposition_for(credential)
      )

      redirect_to url, allow_other_host: true, status: :see_other
    rescue KeyError => e
      Rails.logger.error("R2 credential download configuration error: #{e.message}")
      redirect_back_or_to "/admin", alert: "Credential downloads are not configured."
    end

    private

    def require_admin
      return if current_user&.is_admin?

      redirect_to account_settings_path, alert: "Admin access required."
    end

    def content_disposition_for(credential)
      filename = credential.credential_document_original_name.presence ||
        File.basename(credential.credential_document.to_s)
      %(attachment; filename="#{filename.gsub('"', "")}")
    end

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
