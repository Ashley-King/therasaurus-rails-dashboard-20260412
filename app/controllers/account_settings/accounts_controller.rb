module AccountSettings
  class AccountsController < BaseController
    def show
    end

    def update
      if params[:practice_image_key].present?
        update_practice_image
      else
        update_account_details
      end
    end

    private

    def update_practice_image
      key = params[:practice_image_key].to_s

      # Keys are generated server-side in PresignedUploadsController and
      # must start with the profiles/ prefix. Reject anything else so a
      # client can't write an arbitrary key onto the therapist record.
      unless key.start_with?("profiles/")
        return render json: { error: "Invalid image key" }, status: :unprocessable_entity
      end

      therapist.update!(practice_image_key: key)
      render json: { practice_image_url: therapist.practice_image_url }
    end

    def update_account_details
      if therapist.update(account_params)
        redirect_to account_settings_path, notice: "Account updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def account_params
      params.require(:therapist).permit(:first_name, :last_name, :profession_id, :credentials)
    end
  end
end
