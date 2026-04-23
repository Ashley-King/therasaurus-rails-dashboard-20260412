module AboutYou
  class PrimaryCredentialsController < BaseController
    def show
      @states = State.order(:name)
      @credential = therapist.user_credential || therapist.build_user_credential
    end

    def update
      @credential = therapist.user_credential || therapist.build_user_credential
      previous_type = @credential.credential_type

      @credential.assign_attributes(credential_params)
      clear_irrelevant_fields
      reset_review_state_if_type_changed(previous_type)

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
      permitted = params.require(:user_credential).permit(
        :credential_type,
        # State license
        :license_id, :license_state_id,
        :license_expiration_month, :license_expiration_year,
        # Organization
        :organization_name, :organization_credential_id,
        :organization_expiration_month, :organization_expiration_year,
        :organization_credential_level,
        # Supervised
        :supervisor_name,
        # Common
        :credential_document, :credential_document_original_name,
        :credential_note
      )

      # Expirations are entered as two fields (MM + YYYY). Combine into the
      # last day of the selected month and write to the date column.
      permitted[:license_expiration_date] = build_end_of_month(
        permitted.delete(:license_expiration_month),
        permitted.delete(:license_expiration_year)
      )
      permitted[:organization_expiration_date] = build_end_of_month(
        permitted.delete(:organization_expiration_month),
        permitted.delete(:organization_expiration_year)
      )

      permitted
    end

    def build_end_of_month(month, year)
      return nil if month.blank? || year.blank?

      Date.new(year.to_i, month.to_i, 1).end_of_month
    rescue ArgumentError
      nil
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

    # A therapist switching credential types effectively submits a new
    # credential for verification. Drop the old document + reset review
    # state so the admin re-verifies against the new type's paperwork.
    def reset_review_state_if_type_changed(previous_type)
      return if previous_type.blank?
      return if previous_type == @credential.credential_type

      @credential.credential_document = nil
      @credential.credential_document_original_name = nil
      @credential.credential_status = :pending_review
      @credential.verified_at = nil
      @credential.pending_since = Time.current
    end
  end
end
