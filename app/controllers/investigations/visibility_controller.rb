module Investigations
  class VisibilityController < ApplicationController
    before_action :set_investigation
    before_action :authorize_investigation

    def show
      @last_update_visibility_activity = @investigation.activities.where(type: "AuditActivity::Investigation::UpdateVisibility").order(:created_at).first
    end

    def update
      if @investigation.update(visibility_params)
        redirect_to investigation_path(@investigation),
                    flash: {
                      success: I18n.t(".investigations.visibility.updated", case_type: @investigation.case_type.upcase_first, status: @investigation.decorate.visibility_status)
                    }
      else
        format.html { render :new }
      end
    end

  private

    def set_investigation
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
    end

    def authorize_investigation
      authorize @investigation, :change_owner_or_status?
    end

    def visibility_params
      params.require(:investigation).permit(:is_private, :visibility_rationale)
    end
  end
end
