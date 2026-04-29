module YourPractice
  class FeesPaymentsController < BaseController
    def show
      @payment_methods = PaymentMethod.order(:name)
      @selected_insurance = load_selected_insurance
    end

    def update
      submitted_insurance_ids = Array(params.dig(:therapist, :insurance_company_ids)).reject(&:blank?)
      submitted_insurance_names = Array(params.dig(:therapist, :insurance_company_names)).reject(&:blank?)
      resolved_insurance_ids = resolve_insurance_ids(submitted_insurance_ids, submitted_insurance_names)

      ActiveRecord::Base.transaction do
        therapist.assign_attributes(fees_payments_params)
        therapist.insurance_company_ids = resolved_insurance_ids
        therapist.save!
      end

      redirect_to fees_payment_path, notice: "Fees and payments updated."
    rescue ActiveRecord::RecordInvalid
      flash.now[:alert] = "Please fix the errors below."
      @payment_methods = PaymentMethod.order(:name)
      @selected_insurance = rebuild_selected_insurance(submitted_insurance_ids, submitted_insurance_names)
      render :show, status: :unprocessable_entity
    end

    private

    def fees_payments_params
      params.require(:therapist).permit(
        :evaluation_fee, :therapy_fee, :group_therapy_fee,
        :consultation_fee, :late_cancellation_fee,
        :fee_notes, :appointment_cancellation_policy,
        payment_method_ids: []
      )
    end

    def resolve_insurance_ids(ids, names)
      existing = InsuranceCompany.visible_to(therapist).where(id: ids).pluck(:id)
      submitted = names.filter_map { |n| InsuranceCompany.find_or_submit(name: n, therapist: therapist)&.id }
      (existing + submitted).uniq
    end

    def load_selected_insurance
      therapist.insurance_companies.order(Arel.sql("lower(name)")).map do |c|
        { id: c.id, name: c.name, status: c.status }
      end
    end

    def rebuild_selected_insurance(ids, names)
      existing = InsuranceCompany.visible_to(therapist).where(id: ids).map do |c|
        { id: c.id, name: c.name, status: c.status }
      end
      pending = names.map { |n| { id: nil, name: n, status: "pending" } }
      existing + pending
    end
  end
end
