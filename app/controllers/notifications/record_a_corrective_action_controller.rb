module Notifications
  class RecordACorrectiveActionController < ApplicationController
    include CorrectiveActionsConcern
    before_action :set_notification
    before_action :validate_step
    before_action :set_corrective_action, only: %i[edit update]
    before_action :set_notification_breadcrumbs

    def new
      @corrective_action_form = CorrectiveActionForm.new

      # Set the investigation product if provided
      if params[:investigation_product_ids].present?
        @investigation_product_id = params[:investigation_product_ids]
        @corrective_action_form.investigation_product_id = @investigation_product_id
      end

      render :new
    end

    def create
      # Create the form with the parameters
      @corrective_action_form = CorrectiveActionForm.new(corrective_action_params.merge(duration: "unknown"))

      # Explicitly set the date fields from the form parameters
      @corrective_action_form.date_decided = {
        year: params[:corrective_action]["date_decided(1i)"],
        month: params[:corrective_action]["date_decided(2i)"],
        day: params[:corrective_action]["date_decided(3i)"]
      }

      @corrective_action_form.cache_file!(current_user)

      if @corrective_action_form.valid?(:add_corrective_action)
        result = AddCorrectiveActionToNotification.call(
          @corrective_action_form
            .serializable_hash(except: :further_corrective_action)
            .merge(user: current_user, notification: @notification)
        )

        if result.success?
          redirect_to notification_path(@notification), flash: { success: "The corrective action was added" }
        else
          render :new
        end
      else
        render :new
      end
    end

    def edit
      @corrective_action_form = CorrectiveActionForm.from(@corrective_action)
      @file_blob = @corrective_action.document_blob
      render :edit
    end

    def update
      # Create the form with the parameters
      @corrective_action_form = CorrectiveActionForm.new(corrective_action_params.merge(duration: "unknown"))

      # Explicitly set the date fields from the form parameters
      @corrective_action_form.date_decided = {
        year: params[:corrective_action]["date_decided(1i)"],
        month: params[:corrective_action]["date_decided(2i)"],
        day: params[:corrective_action]["date_decided(3i)"]
      }

      @corrective_action_form.cache_file!(current_user)

      if @corrective_action_form.valid?
        UpdateCorrectiveAction.call!(
          corrective_action: @corrective_action,
          investigation_product_id: @corrective_action.investigation_product_id,
          action: @corrective_action_form.action,
          has_online_recall_information: @corrective_action_form.has_online_recall_information,
          online_recall_information: @corrective_action_form.online_recall_information,
          date_decided: @corrective_action_form.date_decided,
          legislation: @corrective_action_form.legislation,
          business_id: @corrective_action_form.business_id,
          measure_type: @corrective_action_form.measure_type,
          duration: @corrective_action_form.duration,
          geographic_scopes: @corrective_action_form.geographic_scopes,
          details: @corrective_action_form.details,
          related_file: @corrective_action_form.related_file,
          document: @corrective_action_form.document,
          changes: @corrective_action_form.changes,
          user: current_user,
          silent: true
        )

        redirect_to notification_path(@notification), flash: { success: "The corrective action was updated" }
      else
        render :edit
      end
    end

  private

    def set_notification
      @notification = Investigation::Notification.find_by!(pretty_id: params[:notification_pretty_id])
    end

    def set_corrective_action
      @corrective_action = @notification.corrective_actions.find(params[:id])
    end

    def validate_step
      # Ensure objects exist
      unless @notification && current_user
        redirect_to "/404" and return
      end

      # Return forbidden status if not authorized
      render "errors/forbidden", status: :forbidden unless user_can_edit?
    end

    def user_can_edit?
      user_team = current_user.team
      return false if @notification.teams_with_read_only_access.include?(user_team)

      [@notification.creator_user, @notification.owner_user].include?(current_user) ||
        [@notification.owner_team, @notification.creator_team].include?(user_team) ||
        @notification.non_owner_teams_with_edit_access.include?(user_team)
    end

    def set_notification_breadcrumbs
      breadcrumb "notifications.label", :your_notifications
      breadcrumb "All notifications - Search", :notifications_path
      breadcrumb @notification.pretty_id, notification_path(@notification)
    end

    def corrective_action_params
      return {} unless params[:corrective_action]

      allowed_params = params.require(:corrective_action).permit(
        :action,
        :has_online_recall_information,
        :online_recall_information,
        :investigation_product_id,
        :business_id,
        :measure_type,
        :duration,
        :details,
        :related_file,
        :document,
        :existing_document_file_id,
        geographic_scopes: [],
        legislation: []
      ).merge(
        "date_decided(1i)" => params[:corrective_action]["date_decided(1i)"],
        "date_decided(2i)" => params[:corrective_action]["date_decided(2i)"],
        "date_decided(3i)" => params[:corrective_action]["date_decided(3i)"]
      )

      # The form builder inserts an empty hidden field that needs to be removed before validation and saving
      allowed_params[:legislation].reject!(&:blank?) if allowed_params[:legislation].present?
      allowed_params[:geographic_scopes].reject!(&:blank?) if allowed_params[:geographic_scopes].present?
      allowed_params
    end
  end
end
