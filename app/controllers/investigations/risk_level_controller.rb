module Investigations
  class RiskLevelController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_investigation_updates
    before_action :set_investigation_breadcrumbs

    def show
      @risk_level_form = RiskLevelForm.new(risk_level: @investigation.risk_level)
    end

    def update
      @risk_level_form = RiskLevelForm.new(params.require(:investigation).permit(:risk_level))
      return render :show unless @risk_level_form.valid?

      result = ChangeNotificationRiskLevel.call!(
        @risk_level_form.attributes.merge(notification: @investigation, user: current_user)
      )
      ahoy.track "Updated risk level", { notification_id: @investigation.id }
      set_success_flash_message(result)
      redirect_to investigation_path(@investigation)
    end

  private

    def set_success_flash_message(result)
      return if result.change_action.blank?

      flash[:success] = I18n.t(".success.#{result.change_action}",
                               scope: "investigations.risk_level",
                               level: result.updated_risk_level.downcase)
    end
  end
end
