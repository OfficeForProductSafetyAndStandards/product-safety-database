module Investigations
  class OverseasRegulatorController < ApplicationController
    def edit
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize investigation, :change_overseas_regulator?
      @overseas_regulator_form = OverseasRegulatorForm.from(investigation)
      @investigation = investigation.decorate
    end

    def update
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize investigation, :change_overseas_regulator?
      @overseas_regulator_form = OverseasRegulatorForm.new(overseas_regulator_params)

      if @overseas_regulator_form.valid?
        ChangeOverseasRegulator.call!(
          @overseas_regulator_form.serializable_hash.merge({
            investigation:,
            user: current_user
          })
        )

        @investigation = investigation.decorate
        redirect_to investigation_path(@investigation), flash: { success: "The overseas regulator was updated." }
      else
        @investigation = investigation.decorate
        render :edit
      end
    end

  private

    def overseas_regulator_params
      params.require(:investigation).permit(:is_from_overseas_regulator, :overseas_regulator_country)
    end
  end
end
