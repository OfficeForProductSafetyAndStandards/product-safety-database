module Investigations
  class CorrectiveActionsController < ApplicationController
    include CorrectiveActionsConcern

    def new
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize investigation, :update?
      @corrective_action_form = CorrectiveActionForm.new
      @investigation = investigation.decorate
    end

    def create
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      authorize investigation, :update?

      @corrective_action_form = CorrectiveActionForm.new(corrective_action_params)

      @investigation = investigation.decorate
      @file_blob = @corrective_action_form.document
      return render :new if @corrective_action_form.invalid?(:add_corrective_action)

      result = AddCorrectiveActionToCase.call(
        @corrective_action_form
          .serializable_hash(except: :further_corrective_action)
          .merge(user: current_user, investigation:)
      )

      if result.success?
        return redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
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
      @file_blob              = corrective_action.document_blob
      @investigation          = investigation.decorate

      @corrective_action_form.assign_attributes(corrective_action_params)

      return render :edit if @corrective_action_form.invalid?(:edit_corrective_action)

      UpdateCorrectiveAction.call!(
        @corrective_action_form
          .serializable_hash
          .merge(
            user: current_user,
            corrective_action:,
            changes: @corrective_action_form.changes
          )
      )

      redirect_to investigation_supporting_information_index_path(investigation), flash: { success: "The supporting information was updated" }
    end
  end
end
