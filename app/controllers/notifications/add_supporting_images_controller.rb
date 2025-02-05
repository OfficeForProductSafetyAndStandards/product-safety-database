module Notifications
  class AddSupportingImagesController < ApplicationController
    include BreadcrumbHelper

    before_action :set_notification
    before_action :set_image_upload, only: [:show]
    before_action :set_remove_image_upload, only: [:remove_upload]

    breadcrumb "cases.label", :your_cases_investigations

    def show
      @image_upload = ImageUpload.new(upload_model: @notification)
      render :add_supporting_images
    end

    def update
      flash[:success] = nil
      @image_upload = ImageUpload.new(upload_model: @notification)

      if image_upload_params[:file_upload].present?
        begin
          file = ActiveStorage::Blob.create_and_upload!(
            io: image_upload_params[:file_upload],
            filename: image_upload_params[:file_upload].original_filename,
            content_type: image_upload_params[:file_upload].content_type
          )
          file.analyze_later
          @image_upload = ImageUpload.new(file_upload: file, upload_model: @notification, created_by: current_user.id)

          if @image_upload.valid?
            @image_upload.save!
            @notification.image_upload_ids.push(@image_upload.id)
            @notification.save!
            flash[:success] = "Supporting image uploaded successfully"

            if params[:final] == "true"
              redirect_to notification_path(@notification)
            else
              redirect_to notification_add_supporting_images_path(@notification)
            end
          else
            file.purge
            render :add_supporting_images
          end
        rescue ActiveStorage::IntegrityError
          @image_upload.errors.add(:file_upload, "must be a GIF, JPEG, PNG, WEBP or HEIC/HEIF file")
          render :add_supporting_images
        end
      elsif params[:final] == "true"
        redirect_to notification_path(@notification)
      else
        redirect_to notification_add_supporting_images_path(@notification)
      end
    end

    def remove_upload
      if request.delete?
        @image_upload.destroy!
        @notification.image_upload_ids.delete(@image_upload.id)
        @notification.save!
        flash[:success] = "Supporting image removed successfully"
        redirect_to notification_add_supporting_images_path(@notification)
      else
        render :remove_upload
      end
    end

  private

    def set_notification
      @notification = Investigation.find_by!(pretty_id: params[:notification_pretty_id])
      authorize @notification, :update?
    end

    def set_image_upload
      @image_upload = ImageUpload.new
    end

    def set_remove_image_upload
      @image_upload = ImageUpload.find(params[:upload_id])
      raise ActiveRecord::RecordNotFound unless @image_upload.upload_model == @notification
    end

    def image_upload_params
      params.require(:image_upload).permit(:file_upload)
    end
  end
end
