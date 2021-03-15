module Investigations
  class NotifyingCountryController < ApplicationController
    before_action :set_investigation
    before_action :authorize_user

    def edit
      @notifying_country_form = NotifyingCountryForm.from(@investigation)
    end

    def update
      @notifying_country_form = NotifyingCountryForm.new(country: params["investigation"]["country"])

      if @notifying_country_form.valid?
        result = UpdateNotifyingCountry.call!(
          @notifying_country_form.serializable_hash.merge({
            investigation: @investigation,
            user: current_user
          })
        )

        redirect_to investigation_path(@investigation), flash: { success: "#{@investigation.pretty_id} was successfully updated." }
      else
        render :edit
      end
    end

    private

    def set_investigation
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
    end

    def authorize_user
      authorize @investigation, :change_notifying_country?
    end
  end
end
