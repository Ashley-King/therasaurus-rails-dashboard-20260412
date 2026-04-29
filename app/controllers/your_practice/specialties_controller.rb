module YourPractice
  class SpecialtiesController < BaseController
    MAX_FOCUS = 5

    def show
      load_form_data
    end

    def update
      selected_ids = Array(params.dig(:therapist, :specialty_ids)).reject(&:blank?).uniq
      focus_ids = Array(params.dig(:therapist, :focus_specialty_ids)).reject(&:blank?).uniq
      focus_ids &= selected_ids
      focus_ids = focus_ids.first(MAX_FOCUS)

      ActiveRecord::Base.transaction do
        therapist.practice_specialties.where.not(specialty_id: selected_ids).destroy_all
        existing = therapist.practice_specialties.index_by { |ps| ps.specialty_id.to_s }
        selected_ids.each do |id|
          is_focus = focus_ids.include?(id)
          if (ps = existing[id])
            ps.update!(is_focus: is_focus) if ps.is_focus != is_focus
          else
            therapist.practice_specialties.create!(specialty_id: id, is_focus: is_focus)
          end
        end
      end

      redirect_to specialties_path, notice: "Specialties updated."
    end

    private

    def load_form_data
      @specialty_categories = SpecialtyCategory.order(:name).pluck(:id, :name)
      @specialties = Specialty
        .includes(:specialty_categories)
        .order(Arel.sql("lower(name)"))
        .map do |s|
          {
            id: s.id,
            name: s.name,
            category_ids: s.specialty_categories.map(&:id)
          }
        end

      selections = therapist.practice_specialties.pluck(:specialty_id, :is_focus)
      @selected_specialty_ids = selections.map { |id, _| id.to_s }
      @focus_specialty_ids = selections.filter_map { |id, focus| id.to_s if focus }
      @max_focus = MAX_FOCUS
    end
  end
end
