module Dashboard
  class ClientsAvailabilitiesController < BaseController
    def show
    end

    def update
      if therapist.update(clients_availability_params)
        redirect_to dashboard_clients_availability_path, notice: "Availability updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def clients_availability_params
      params.require(:therapist).permit(
        :accepting_new_clients, :has_waitlist, :free_phone_call,
        :early_morning, :evening, :weekend,
        :in_person, :virtual, :availability_notes,
        session_format_ids: []
      )
    end
  end
end
