class Avo::Resources::Therapist < Avo::BaseResource
  self.title = :display_name
  self.search = {
    query: -> {
      query.ransack(
        first_name_cont: params[:q],
        last_name_cont: params[:q],
        m: "or"
      ).result(distinct: false)
    }
  }

  def fields
    field :id, as: :id
    field :first_name, as: :text
    field :last_name, as: :text
    field :profile_slug, as: :text
    field :pronouns, as: :text
    field :credentials, as: :text

    field :user, as: :belongs_to
    field :profession, as: :belongs_to
    field :country, as: :belongs_to

    field :year_began_practice, as: :number
    field :practice_name, as: :text
    field :use_practice_name, as: :boolean
    field :practice_website_url, as: :text, only_on: :forms
    field :practice_video_url, as: :text, only_on: :forms
    field :practice_image_key, as: :text, only_on: :forms,
      help: "R2 object key (not a full URL). The public URL is built on demand."
    field :practice_description, as: :textarea, only_on: :forms
    field :personal_statement, as: :textarea, only_on: :forms

    field :phone_number, as: :text
    field :phone_ext, as: :text
    field :show_phone_number, as: :boolean

    field :evaluation_fee, as: :number
    field :therapy_fee, as: :number
    field :group_therapy_fee, as: :number
    field :consultation_fee, as: :number
    field :late_cancellation_fee, as: :number
    field :fee_notes, as: :text, only_on: :forms
    field :free_phone_call, as: :boolean

    field :accepting_new_clients, as: :boolean
    field :has_waitlist, as: :boolean
    field :early_morning, as: :boolean
    field :evening, as: :boolean
    field :weekend, as: :boolean
    field :in_person, as: :boolean
    field :virtual, as: :boolean
    field :accepts_insurance, as: :boolean
    field :availability_notes, as: :text, only_on: :forms

    field :telehealth_platform, as: :text, only_on: :forms
    field :parking_transit_notes, as: :textarea, only_on: :forms
    field :appointment_cancellation_policy, as: :textarea, only_on: :forms
    field :allow_messages, as: :boolean

    field :locations, as: :has_many
    field :user_credential, as: :has_one
    field :therapist_education, as: :has_many
    field :therapist_continuing_education, as: :has_many
    field :business_hours, as: :has_many
    field :specialties, as: :has_many, through: :practice_specialties
    field :services, as: :has_many, through: :practice_services
    field :insurance_companies, as: :has_many, through: :practice_insurance_companies
    field :languages, as: :has_many, through: :practice_languages
    field :age_groups, as: :has_many, through: :practice_age_groups
    field :faiths, as: :has_many, through: :practice_faiths
    field :payment_methods, as: :has_many, through: :practice_payment_methods
    field :accessibility_options, as: :has_many, through: :practice_accessibility_options
    field :session_formats, as: :has_many, through: :practice_session_formats
    field :telehealth_platforms, as: :has_many, through: :practice_telehealth_platforms

    field :created_at, as: :date_time, sortable: true, only_on: :index
  end
end
