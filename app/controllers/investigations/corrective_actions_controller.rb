module Investigations
  class CorrectiveActionsController < Investigations::BaseController
    include CorrectiveActionsConcern
    before_action :set_investigation
    before_action :authorize_investigation_updates, except: %i[show]
    before_action :set_investigation_breadcrumbs

    def new
      @corrective_action_form = CorrectiveActionForm.new
    end

    def create
      @corrective_action_form = CorrectiveActionForm.new(corrective_action_params)
      @corrective_action_form.legislation.reject!(&:blank?)
      @file_blob = @corrective_action_form.document
      return render :new if @corrective_action_form.invalid?(:add_corrective_action)

      result = AddCorrectiveActionToNotification.call(
        @corrective_action_form
          .serializable_hash(except: :further_corrective_action)
          .merge(user: current_user, notification: @investigation)
      )

      if result.success?
        ahoy.track "Added corrective action", { investigation_id: @investigation.id }
        return redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
      end

      render :new
    end

    def show
      authorize @investigation, :view_non_protected_details?
      @corrective_action = @investigation.corrective_actions.find(params[:id]).decorate
    end

    def edit
      corrective_action = @investigation.corrective_actions.find(params[:id])
      @corrective_action_form = CorrectiveActionForm.from(corrective_action)

      @file_blob = corrective_action.document_blob
    end

    def update
      corrective_action       = @investigation.corrective_actions.find(params[:id])
      @corrective_action_form = CorrectiveActionForm.from(corrective_action)
      @file_blob              = corrective_action.document_blob

      @corrective_action_form.assign_attributes(corrective_action_params)
      @corrective_action_form.legislation.reject!(&:blank?)
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

      ahoy.track "Updated corrective action", { notification_id: @investigation.id }

      if params[:bulk_products_upload_id].present?
        redirect_to check_corrective_actions_bulk_upload_products_path(bulk_products_upload_id: params[:bulk_products_upload_id])
      else
        redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
      end
    end
  end
end
