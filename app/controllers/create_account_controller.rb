class CreateAccountController < ApplicationController
  include Authentication

  layout "auth"

  before_action :require_auth
  before_action :redirect_if_profile_complete

  # GET /create-account
  def new
    @professions = Profession.order(:name)
    @countries = Country.order(:name)
    @states = State.order(:code)
  end

  # POST /create-account
  def create
    @professions = Profession.order(:name)
    @countries = Country.order(:name)
    @states = State.order(:code)

    profession = Profession.find_by(id: params[:profession_id])
    country = Country.find_by(id: params[:country_id])

    unless profession
      flash.now[:alert] = "Please select a valid profession."
      return render :new, status: :unprocessable_entity
    end

    unless country
      flash.now[:alert] = "Please select a valid country."
      return render :new, status: :unprocessable_entity
    end

    state_code = params[:state].to_s.strip.upcase
    zip_code = params[:zip].to_s.strip

    unless state_code.match?(/\A[A-Z]{2}\z/)
      flash.now[:alert] = "State must be a valid 2-letter code."
      return render :new, status: :unprocessable_entity
    end

    unless zip_code.match?(/\A\d{5}\z/)
      flash.now[:alert] = "ZIP code must be exactly 5 digits."
      return render :new, status: :unprocessable_entity
    end

    unique_id = generate_unique_id
    city = params[:city].to_s.strip

    ActiveRecord::Base.transaction do
      @therapist = current_user.build_therapist(
        first_name: params[:first_name].to_s.strip,
        last_name: params[:last_name].to_s.strip,
        credentials: params[:credentials].to_s.strip.presence,
        profession: profession,
        country: country,
        profile_slug: generate_profile_slug(params[:first_name], params[:last_name], profession, city, state_code, unique_id),
        unique_id: unique_id
      )

      unless @therapist.save
        flash.now[:alert] = @therapist.errors.full_messages.join(", ")
        raise ActiveRecord::Rollback
      end

      @location = @therapist.locations.build(
        location_type: :primary,
        street_address: params[:street_address].to_s.strip,
        street_address2: params[:street_address2].to_s.strip.presence,
        city: params[:city].to_s.strip,
        state: state_code,
        zip: zip_code,
        show_street_address: params[:show_street_address] == "1"
      )

      unless @location.save
        flash.now[:alert] = @location.errors.full_messages.join(", ")
        raise ActiveRecord::Rollback
      end
    end

    if @therapist&.persisted? && @location&.persisted?
      GeocodeLocationJob.perform_later(@location.id)
      redirect_to dashboard_path, notice: "Your account has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_profile_complete
    return if current_user.is_admin?

    redirect_to dashboard_path if profile_complete?
  end

  def generate_profile_slug(first_name, last_name, profession, city, state_code, unique_id)
    "#{first_name} #{last_name} #{profession.slug} #{city} #{state_code}".parameterize + "/#{unique_id}"
  end

  def generate_unique_id
    loop do
      id = rand(1_000_001..9_999_999).to_s
      return id unless Therapist.exists?(unique_id: id)
    end
  end
end
