module AboutYou
  class ProfessionalDevelopmentsController < BaseController
    MAX_TRAININGS = 3

    def show
      @training_rows = display_rows_from_db
    end

    def update
      rows = submitted_rows

      ActiveRecord::Base.transaction do
        therapist.therapist_continuing_education.destroy_all
        rows.each { |row| create_entry(row) }
      end

      redirect_to professional_development_path, notice: "Additional training updated."
    rescue ActiveRecord::RecordInvalid => e
      @training_rows = display_rows_from_params
      @row_errors = extract_row_errors(e.record)
      flash.now[:alert] = "Please fix the errors below."
      render :show, status: :unprocessable_entity
    end

    private

    def submitted_rows
      rows = params[:training]
      return [] unless rows.is_a?(ActionController::Parameters)

      rows.to_unsafe_h
        .sort_by { |k, _| k.to_i }
        .map { |_, v| v.to_h.symbolize_keys }
        .first(MAX_TRAININGS)
    end

    def create_entry(row)
      return if row[:description].blank?

      # Set therapist_id directly instead of going through the association
      # so this record doesn't end up in therapist.therapist_continuing_education
      # in memory during the destroy_all step of the same transaction.
      TherapistContinuingEducation.create!(
        therapist_id: therapist.id,
        year: row[:year].presence,
        description: row[:description].strip
      )
    end

    def display_rows_from_db
      therapist.therapist_continuing_education.order(:created_at).map do |ce|
        { year: ce.year, description: ce.description }
      end
    end

    def display_rows_from_params
      submitted_rows.map do |r|
        { year: r[:year].presence, description: r[:description].presence }
      end
    end

    def extract_row_errors(record)
      return {} unless record.is_a?(TherapistContinuingEducation)

      # We don't track which row index failed, so surface the errors at the
      # form level via flash.now[:alert]. Per-row errors would need a richer
      # submission model; not worth it for a 3-row form.
      record.errors.full_messages
    end
  end
end
