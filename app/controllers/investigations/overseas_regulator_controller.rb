module Investigations
  class OverseasRegulatorController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_change_overseas_regulator
    before_action :set_investigation_breadcrumbs

    def edit
      @overseas_regulator_form = OverseasRegulatorForm.from(@investigation)
    end

    def update
      @overseas_regulator_form = OverseasRegulatorForm.new(overseas_regulator_params)

      if @overseas_regulator_form.valid?
        ChangeOverseasRegulator.call!(
          @overseas_regulator_form.serializable_hash.merge({
            investigation: @investigation,
            user: current_user
          })
        )
        redirect_to investigation_path(@investigation), flash: { success: "The overseas regulator was updated." }
      else
        render :edit
      end
    end

  private

    def authorize_change_overseas_regulator
      authorize @investigation, :change_overseas_regulator?
    end

    def overseas_regulator_params
      params.require(:investigation).permit(:is_from_overseas_regulator, :overseas_regulator_country)
    end
  end
end
