module Investigations
  class NotifyingCountryController < ApplicationController
    def edit
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize investigation, :change_notifying_country?
      @notifying_country_form = NotifyingCountryForm.from(investigation)
      @investigation = investigation.decorate
    end

    def update
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize investigation, :change_notifying_country?
      @notifying_country_form = NotifyingCountryForm.new(notifying_country_params)

      if @notifying_country_form.valid?
        ChangeNotifyingCountry.call!(
          @notifying_country_form.serializable_hash.merge({
            investigation:,
            user: current_user
          })
        )

        @investigation = investigation.decorate
        redirect_to investigation_path(@investigation), flash: { success: "The notifying country was updated." }
      else
        @investigation = investigation.decorate
        render :edit
      end
    end

  private

    def notifying_country_params
      params.require(:investigation).permit(:country)
    end
  end
end
