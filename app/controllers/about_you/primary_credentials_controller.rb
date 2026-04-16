module AboutYou
  class PrimaryCredentialsController < BaseController
    def show
      @states = State.order(:name)
      @credential = therapist.user_credentials.first || therapist.user_credentials.build
    end

    def update
      @credential = therapist.user_credentials.first || therapist.user_credentials.build

      @credential.assign_attributes(credential_params)
      clear_irrelevant_fields

      if @credential.save
        redirect_to primary_credential_path, notice: "Credential updated."
      else
        @states = State.order(:name)
        flash.now[:alert] = "Please fix the errors below."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def credential_params
      params.require(:user_credential).permit(
        :credential_type,
        # State license
        :license_id, :license_expiration_date, :license_state_id,
        # Organization
        :organization_name, :organization_credential_id,
        :organization_expiration_date, :organization_credential_level,
        # Supervised
        :supervisor_name,
        # Common
        :credential_document, :credential_document_original_name,
        :credential_note
      )
    end

    # When switching credential types, blank out fields that belong to other types
    def clear_irrelevant_fields
      case @credential.credential_type
      when "state_license"
        @credential.organization_name = nil
        @credential.organization_credential_id = nil
        @credential.organization_expiration_date = nil
        @credential.organization_credential_level = nil
        @credential.supervisor_name = nil
      when "organization"
        @credential.license_id = nil
        @credential.license_expiration_date = nil
        @credential.license_state_id = nil
        @credential.supervisor_name = nil
      when "supervised"
        @credential.organization_name = nil
        @credential.organization_credential_id = nil
        @credential.organization_expiration_date = nil
        @credential.organization_credential_level = nil
      end
    end
  end
end
