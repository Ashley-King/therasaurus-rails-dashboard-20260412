module YourPractice
  class ClientsController < BaseController
    def show
      @age_groups = AgeGroup.order(:sort_order)
      @languages = Language.order(:name)
      @faiths = Faith.order(:name)
    end

    def update
      if therapist.update(clients_params)
        redirect_to clients_path, notice: "Clients updated."
      else
        flash.now[:alert] = "Please fix the errors below."
        @age_groups = AgeGroup.order(:sort_order)
        @languages = Language.order(:name)
        @faiths = Faith.order(:name)
        render :show, status: :unprocessable_entity
      end
    end

    private

    def clients_params
      params.require(:therapist).permit(
        age_group_ids: [], language_ids: [], faith_ids: []
      )
    end
  end
end
