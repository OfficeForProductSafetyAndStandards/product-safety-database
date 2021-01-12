module Investigations
  class CorrectiveActionsController < ApplicationController
    include CorrectiveActionsConcern

    def new
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize investigation, :view_non_protected_details?
      @corrective_action_form = CorrectiveActionForm.new
      @investigation = investigation.decorate
    end

    def create
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize investigation, :view_non_protected_details?

      @corrective_action_form = CorrectiveActionForm.new(corrective_action_params)

      @investigation = investigation.decorate
      return render :new if @corrective_action_form.invalid?

      result = AddCorrectiveActionToCase.call(
        @corrective_action_form
          .serializable_hash(except: :further_corrctive_action)
          .merge(user: current_user, investigation: investigation)
      )

      if result.success?
        return redirect_to investigation_corrective_action_path(@investigation, result.corrective_action), flash: { success: t(".success") }
      end

      render :new
    end

    def show
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
      authorize @investigation, :view_non_protected_details?
      @corrective_action = @investigation.corrective_actions.find(params[:id]).decorate
    end

    def edit
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize investigation, :update?
      corrective_action = investigation.corrective_actions.find(params[:id])
      @corrective_action_form = CorrectiveActionForm.from(corrective_action)

      @file_blob = corrective_action.document_blob
      @investigation = investigation.decorate
    end

    def update
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize investigation, :update?

      corrective_action       = investigation.corrective_actions.find(params[:id])
      @corrective_action_form = CorrectiveActionForm.from(corrective_action)
      @investigation          = investigation.decorate

      @corrective_action_form.assign_attributes(corrective_action_params)

      return render :edit if @corrective_action_form.invalid?

      result = UpdateCorrectiveAction.call(
        @corrective_action_form
          .serializable_hash(except: :further_corrctive_action)
          .merge(
            user: current_user,
            corrective_action: corrective_action,
            changes: @corrective_action_form.changes
          )
      )

      return redirect_to investigation_corrective_action_path(investigation, result.corrective_action), flash: { success: t(".success") } if result.success?

      render :edit
    end
  end
end
