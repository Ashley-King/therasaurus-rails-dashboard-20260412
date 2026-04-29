module YourPractice
  class FaqsController < BaseController
    def show
    end

    def update
      if therapist.update(faq_params)
        redirect_to faq_path, notice: "FAQs updated."
      else
        flash.now[:alert] = "Please fix the errors below."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def faq_params
      params.require(:therapist).permit(
        therapist_faqs_attributes: [ :id, :question, :answer, :_destroy ]
      )
    end
  end
end
