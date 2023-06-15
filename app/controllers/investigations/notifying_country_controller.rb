module Investigations
  class NotifyingCountryController < ApplicationController
    before_action :set_investigation
    before_action :set_case_breadcrumbs

    def edit
      @notifying_country_form = NotifyingCountryForm.from(@investigation_object)
    end

    def update
      @notifying_country_form = NotifyingCountryForm.new(notifying_country_params)

      if @notifying_country_form.valid?
        ChangeNotifyingCountry.call!(
          @notifying_country_form.serializable_hash.merge({
            investigation: @investigation_object,
            user: current_user
          })
        )

        @investigation = @investigation_object.decorate
        redirect_to investigation_path(@investigation), flash: { success: "The notifying country was updated" }
      else
        @investigation = @investigation_object.decorate
        render :edit
      end
    end

  private

    def set_investigation
      @investigation_object = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      @investigation = @investigation_object.decorate
      authorize @investigation_object, :change_notifying_country?
    end

    def notifying_country_params
      params.require(:investigation).permit(:notifying_country_uk, :notifying_country_overseas, :overseas_or_uk)
    end
  end
end
