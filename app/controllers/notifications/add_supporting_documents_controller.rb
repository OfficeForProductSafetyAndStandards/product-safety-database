module Notifications
  class AddSupportingDocumentsController < ApplicationController
    include BreadcrumbHelper

    before_action :set_notification
    before_action :validate_step
    before_action :set_document_form, only: [:show]
    before_action :set_remove_document, only: [:remove_upload]

    breadcrumb -> { t("notifications.label") }, :your_notifications_path

    def show
      render "add_supporting_documents"
    end

    def update
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
    end

    def validate_step
      return if !@notification.is_closed? && policy(@notification).update?

      render "errors/forbidden", status: :forbidden
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
