module Notifications
  class AddSupportingImagesController < ApplicationController
    include BreadcrumbHelper

    before_action :set_notification
    before_action :validate_step
    before_action :check_notification_is_open
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
            flash[:error] = @image_upload.errors.full_messages.to_sentence
            render :add_supporting_images
          end
        rescue ActiveStorage::IntegrityError
          @image_upload.errors.add(:file_upload, "must be a GIF, JPEG, PNG, WEBP or HEIC/HEIF file")
          flash[:error] = @image_upload.errors.full_messages.to_sentence
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
        if @image_upload.upload_model != @notification
          head :forbidden
        else
          ActiveRecord::Base.transaction do
            @notification.image_upload_ids.delete(@image_upload.id)
            @notification.save!
            @image_upload.file_upload.purge
            @image_upload.destroy!
          end
          flash[:success] = "Supporting image removed successfully"
          redirect_to notification_add_supporting_images_path(@notification)
        end
      else
        render :remove_upload
      end
    end

  private

    def validate_step
      # Ensure objects exist
      unless @notification && current_user
        redirect_to "/404" and return
      end

      user_team = current_user.team

      # Check if the current user or their team is authorized to edit the notification
      authorized_to_edit =
        [@notification.creator_user, @notification.owner_user].include?(current_user) ||
        [@notification.owner_team, @notification.creator_team].include?(user_team) ||
        @notification.teams_with_edit_access.include?(user_team)

      # Check if the user's team has read-only access
      has_read_only_access = @notification.teams_with_read_only_access.include?(user_team)

      # Return forbidden if not authorized or has read-only access
      if !authorized_to_edit || has_read_only_access
        render "errors/forbidden", status: :forbidden and return
      end
    end

    def set_notification
      @notification = Investigation.find_by!(pretty_id: params[:notification_pretty_id])
    end

    def check_notification_is_open
      return unless @notification.is_closed?

      flash[:warning] = "Cannot edit a closed notification"
      redirect_to notification_path(@notification)
    end

    def set_image_upload
      @image_upload = ImageUpload.new
    end

    def set_remove_image_upload
      @image_upload = ImageUpload.find(params[:upload_id])
    end

    def image_upload_params
      params.require(:image_upload).permit(:file_upload)
    end
  end
end
