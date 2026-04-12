module Dashboard
  class FeesController < BaseController
    def show
    end

    def update
      if therapist.update(fees_params)
        redirect_to dashboard_fees_path, notice: "Fees updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def fees_params
      params.require(:therapist).permit(
        :evaluation_fee, :therapy_fee, :group_therapy_fee,
        :consultation_fee, :late_cancellation_fee, :fee_notes,
        :accepts_insurance
      )
    end
  end
end
