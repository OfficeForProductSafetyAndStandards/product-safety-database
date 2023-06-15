module Investigations
  class OverseasRegulatorController < ApplicationController
    before_action :set_investigation
    before_action :set_case_breadcrumbs

    def edit
      @overseas_regulator_form = OverseasRegulatorForm.from(@investigation_object)
    end

    def update
      @overseas_regulator_form = OverseasRegulatorForm.new(overseas_regulator_params)

      if @overseas_regulator_form.valid?
        ChangeOverseasRegulator.call!(
          @overseas_regulator_form.serializable_hash.merge({
            investigation: @investigation_object,
            user: current_user
          })
        )

        @investigation = @investigation_object.decorate
        redirect_to investigation_path(@investigation), flash: { success: "The overseas regulator was updated." }
      else
        @investigation = @investigation_object.decorate
        render :edit
      end
    end

  private

    def set_investigation
      @investigation_object = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      @investigation = @investigation_object.decorate
      authorize @investigation_object, :change_overseas_regulator?
    end

    def overseas_regulator_params
      params.require(:investigation).permit(:is_from_overseas_regulator, :overseas_regulator_country)
    end
  end
end
