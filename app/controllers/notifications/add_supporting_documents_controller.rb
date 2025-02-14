module Notifications
  class AddSupportingDocumentsController < ApplicationController
    include BreadcrumbHelper

    before_action :set_notification
    before_action :validate_step
    before_action :set_document_upload, only: [:show]
    before_action :set_remove_document_upload, only: [:remove_upload]

    breadcrumb "Notifications", :your_notifications_path

    def show
      @document_upload = @notification.document_uploads.build
      render "add_supporting_documents"
    end

    def update
      flash[:success] = nil
      @document_upload = @notification.document_uploads.build(document_upload_params)

      if @document_upload.save
        flash[:success] = "Supporting document uploaded successfully"
        redirect_to notification_add_supporting_documents_path(@notification)
      else
        render "add_supporting_documents"
      end
    end

    def remove_upload
      if request.delete?
        remove_document
        flash[:success] = "Supporting document removed successfully"
        redirect_to notification_add_supporting_documents_path(@notification)
      else
        render "remove_upload"
      end
    end

  private

    def remove_document
      ActiveRecord::Base.transaction do
        @notification.document_upload_ids.delete(@document_upload.id)
        @notification.save!
        @document_upload.destroy!
      end
    end

    def set_notification
      @notification = Investigation.find_by!(pretty_id: params[:notification_pretty_id])
    end

    def validate_step
      return if @notification.can_be_updated? && policy(@notification).update?

      render "errors/forbidden", status: :forbidden
    end

    def set_document_upload
      @document_upload = @notification.document_uploads.build
    end

    def set_remove_document_upload
      @document_upload = @notification.document_uploads.find(params[:upload_id])
    end

    def document_upload_params
      params.require(:document_upload).permit(:file_upload, :title)
    end
  end
end
