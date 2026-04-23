class Avo::Resources::UserCredential < Avo::BaseResource
  self.title = :credential_type

  def fields
    field :id, as: :id
    field :therapist, as: :belongs_to
    field :credential_type, as: :text
    field :credential_status, as: :select, enum: ::UserCredential.credential_statuses

    field :license_id, as: :text
    field :license_state, as: :belongs_to, foreign_key: :license_state_id
    field :license_expiration_date, as: :date

    field :certificate_id, as: :text
    field :certificate_institution, as: :text
    field :certificate_expiration_date, as: :date

    field :credential_organization, as: :belongs_to
    field :organization_credential_id, as: :text
    field :organization_name, as: :text
    field :organization_expiration_date, as: :date
    field :organization_credential_level, as: :text

    field :credential_document, as: :text,
      help: "R2 object key in the private ptd-credentials bucket."
    field :credential_document_original_name, as: :text
    field :download_document,
      as: :text,
      as_html: true,
      hide_on: :forms,
      format_using: -> {
        next "—" if record.credential_document.blank?

        url = Rails.application.routes.url_helpers.admin_credential_document_path(record.id)
        view_context.link_to("Download", url, target: "_blank", rel: "noopener",
          class: "underline text-blue-600 hover:text-blue-800 hover:underline")
      }
    field :credential_note, as: :textarea

    field :verified_at, as: :date_time
    field :pending_since, as: :date_time
    field :revoked_at, as: :date_time
    field :revoked_reason, as: :textarea
    field :first_submitted_at, as: :date_time
    field :grace_expires_at, as: :date_time

    field :created_at, as: :date_time, sortable: true, only_on: :index
  end

  def actions
    action Avo::Actions::RunR2OrphanCleanup
  end
end
