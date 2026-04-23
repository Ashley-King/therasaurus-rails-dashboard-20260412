module AboutYou
  class EducationsController < BaseController
    MAX_EDUCATION = 2

    def show
      load_form_data
    end

    def update
      therapist.assign_attributes(year_began_practice: params.dig(:therapist, :year_began_practice).presence)
      rows = submitted_rows

      ActiveRecord::Base.transaction do
        therapist.save!
        therapist.therapist_education.destroy_all
        rows.each { |row| create_entry(row) }
      end

      redirect_to education_path, notice: "Education updated."
    rescue ActiveRecord::RecordInvalid
      @education_rows = display_rows_from_params
      @degree_types = DegreeType.approved.order(:name)
      flash.now[:alert] = "Please fix the errors below."
      render :show, status: :unprocessable_entity
    end

    private

    def load_form_data
      @degree_types = DegreeType.approved.order(:name)
      @education_rows = display_rows_from_db
    end

    def submitted_rows
      rows = params[:education]
      return [] unless rows.is_a?(ActionController::Parameters)

      rows.to_unsafe_h
        .sort_by { |k, _| k.to_i }
        .map { |_, v| v.to_h.symbolize_keys }
        .first(MAX_EDUCATION)
    end

    def create_entry(row)
      return if row[:college_id].blank? && row[:college_name].blank?

      college = resolve_college(row)
      unless college&.persisted?
        invalid = TherapistEducation.new
        invalid.errors.add(:college, "could not be added")
        raise ActiveRecord::RecordInvalid, invalid
      end

      # Set therapist_id directly (not the association) so the new record does
      # NOT get added to therapist.therapist_education in memory, which would
      # trigger autosave during the earlier therapist.save! and collide with
      # the destroy_all step.
      TherapistEducation.create!(
        therapist_id: therapist.id,
        college_id: college.id,
        degree_type_id: row[:degree_type_id].presence,
        graduation_year: row[:graduation_year].presence
      )
    end

    def resolve_college(row)
      if row[:college_id].present?
        College.visible_to(therapist).find_by(id: row[:college_id])
      elsif row[:college_name].present?
        College.find_or_submit(name: row[:college_name], therapist: therapist)
      end
    end

    def display_rows_from_db
      therapist.therapist_education.includes(:college, :degree_type).map do |edu|
        {
          college_id: edu.college_id,
          college_name: edu.college&.name,
          college_status: edu.college&.status,
          degree_type_id: edu.degree_type_id,
          graduation_year: edu.graduation_year
        }
      end
    end

    def display_rows_from_params
      rows = submitted_rows
      ids = rows.filter_map { |r| r[:college_id].presence }
      colleges_by_id = College.where(id: ids).index_by { |c| c.id.to_s }

      rows.map do |r|
        college = colleges_by_id[r[:college_id].to_s]
        {
          college_id: r[:college_id].presence,
          college_name: college&.name || r[:college_name].presence,
          college_status: college&.status || (r[:college_name].present? ? "pending" : nil),
          degree_type_id: r[:degree_type_id].presence,
          graduation_year: r[:graduation_year].presence
        }
      end
    end
  end
end
