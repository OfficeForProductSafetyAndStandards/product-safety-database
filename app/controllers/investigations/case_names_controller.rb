module Investigations
  class CaseNamesController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_investigation_updates
    before_action :set_case_breadcrumbs

    def edit
      @case_name_form = CaseNameForm.new(user_title: @investigation.user_title, current_user:)
    end

    def update
      @case_name_form = CaseNameForm.new(case_name_params.merge(current_user:))

      if @case_name_form.valid?
        ChangeCaseName.call!(investigation: @investigation, user_title: @case_name_form.user_title, user: current_user)
        redirect_to investigation_path(@investigation), flash: { success: "The case name was updated" }
      else
        render :edit
      end
    end

  private

    def case_name_params
      params.require(:investigation).permit(:user_title)
    end
  end
end
