module Investigations
  class NotifyingCountryController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_change_notifying_country
    before_action :set_investigation_breadcrumbs

    def edit
      @notifying_country_form = NotifyingCountryForm.from(@investigation)
    end

    def update
      @notifying_country_form = NotifyingCountryForm.new(notifying_country_params)

      if @notifying_country_form.valid?
        ChangeNotifyingCountry.call!(
          @notifying_country_form.serializable_hash.merge({
            investigation: @investigation,
            user: current_user
          })
        )
        ahoy.track "Updated notifying country", { notification_id: @investigation.id }

        redirect_to investigation_path(@investigation), flash: { success: "The notifying country was updated" }
      else
        render :edit
      end
    end

  private

    def authorize_change_notifying_country
      authorize @investigation, :change_notifying_country?
    end

    def notifying_country_params
      params.require(:investigation).permit(:notifying_country_uk, :notifying_country_overseas, :overseas_or_uk)
    end
  end
end
