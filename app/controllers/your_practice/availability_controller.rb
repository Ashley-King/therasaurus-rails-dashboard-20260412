module YourPractice
  class AvailabilityController < BaseController
    def show
      @session_formats = SessionFormat.order(:name)
      @telehealth_platforms = TelehealthPlatform.order(:name)
    end

    def update
      ActiveRecord::Base.transaction do
        therapist.assign_attributes(availability_params)
        therapist.save!
        replace_business_hours
      end

      redirect_to availability_path, notice: "Availability updated."
    rescue ActiveRecord::RecordInvalid
      flash.now[:alert] = "Please fix the errors below."
      @session_formats = SessionFormat.order(:name)
      @telehealth_platforms = TelehealthPlatform.order(:name)
      render :show, status: :unprocessable_entity
    end

    private

    def availability_params
      params.require(:therapist).permit(
        :accepting_new_clients, :has_waitlist, :free_phone_call,
        :in_person, :virtual,
        :early_morning, :evening, :weekend,
        :availability_notes, :telehealth_platform_other, :time_zone,
        session_format_ids: [], telehealth_platform_ids: []
      )
    end

    def replace_business_hours
      submitted = params[:business_hours]
      return if submitted.blank?

      therapist.business_hours.destroy_all

      BusinessHour::DAYS.each do |day_key, day_num|
        attrs = submitted[day_key.to_s] || submitted[day_key]
        next if attrs.blank?
        next if attrs[:closed].to_s == "1"

        therapist.business_hours.create!(
          day_of_week: day_num,
          open_time: attrs[:open],
          close_time: attrs[:close]
        )
      end
    end
  end
end
