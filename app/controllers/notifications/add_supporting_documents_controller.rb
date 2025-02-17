module Notifications
  class AddSupportingDocumentsController < ApplicationController
    include BreadcrumbHelper

    before_action :authenticate_user!
    before_action :set_notification
    before_action :validate_step, except: [:show]
    before_action :validate_view_access, only: [:show]
    before_action :set_document_form, only: [:show]
    before_action :set_remove_document, only: [:remove_upload]

    breadcrumb -> { t("notifications.label") }, :your_notifications_path

    def show
      render "add_supporting_documents"
    end

    def update
      validate_step
      flash[:success] = nil
      @document_form = DocumentForm.new(document_form_params)
      @document_form.cache_file!(current_user)

      if @document_form.valid?
        @notification.documents.attach(@document_form.document)
        flash[:success] = "Supporting document uploaded successfully"
        redirect_to notification_add_supporting_documents_path(@notification)
      else
        render "add_supporting_documents"
      end
    end

    def remove_upload
      validate_step
      if request.delete?
        @upload.destroy!
        flash[:success] = "Supporting document removed successfully"
        redirect_to notification_add_supporting_documents_path(@notification)
      else
        render "remove_upload"
      end
    end

  private

    def set_notification
      @notification = Investigation.find_by!(pretty_id: params[:notification_pretty_id])
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def validate_step
      if @notification.is_closed?
        render "errors/forbidden", status: :forbidden
        return false
      end

      unless policy(@notification).update?
        render "errors/forbidden", status: :forbidden
        return false
      end
      true
    end

    def validate_view_access
      unless policy(@notification).view_non_protected_details?
        render "errors/forbidden", status: :forbidden
        return false
      end
      true
    end

    def set_document_form
      @document_form = DocumentForm.new
    end

    def set_remove_document
      @upload = @notification.documents.find(params[:upload_id])
    end

    def document_form_params
      params.require(:document_form).permit(:document, :title)
    end
  end
end
