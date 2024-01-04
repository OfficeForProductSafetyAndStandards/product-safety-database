class ImageUploadsController < ApplicationController
  include ImageUploadsHelper

  before_action :set_and_authorise_parent

  def new
    @image_upload = ImageUpload.new(upload_model: @parent)
    @parent = @parent.decorate
  end

  def create
    if image_upload_params[:existing_file_upload_file_id].present? && image_upload_params[:file_upload].blank?
      existing_file = existing_file_from_id(image_upload_params[:existing_file_upload_file_id])
      @image_upload = ImageUpload.new(
        image_upload_params.merge(
          file_upload: existing_file, upload_model: @parent, created_by: current_user.id
        )
      )
    elsif image_upload_params[:file_upload].present?
      file = ActiveStorage::Blob.create_and_upload!(
        io: image_upload_params[:file_upload],
        filename: image_upload_params[:file_upload].original_filename,
        content_type: image_upload_params[:file_upload].content_type
      )
      file.analyze_later
      @image_upload = ImageUpload.new(
        image_upload_params.merge(
          file_upload: file, existing_file_upload_file_id: file.signed_id, upload_model: @parent, created_by: current_user.id
        )
      )
    else
      # The image upload won't be valid since there is no file
      @image_upload = ImageUpload.new(image_upload_params.merge(upload_model: @parent, created_by: current_user.id))
    end

    # sleep to give the antivirus checks a chance to be completed before running document form validations
    sleep 3

    if @image_upload.valid?
      @image_upload.save!
      # Manually attach the image upload to its parent model's ID array
      @parent.image_upload_ids.push(@image_upload.id)
      @parent.save!
    else
      @parent = @parent.decorate
      return render :new
    end

    # Reload the uploaded file to get the latest metadata
    @image_upload.file_upload.try(:reload)

    if @image_upload.file_upload.metadata["analyzed"]
      if @image_upload.file_upload.metadata["safe"]
        flash[:success] = t(:image_added)
      else
        flash[:warning] = "File upload must be virus free"
      end
    else
      flash[:information] = "The image did not finish uploading - you must refresh the image"
    end

    if @parent.is_a?(Investigation)
      create_audit_activity
      create_send_notification_email

      redirect_to new_investigation_image_upload_path(@parent, image_upload_id: (params[:image_upload_id] || []).push(@image_upload.id))
    else
      redirect_to product_path(@parent, anchor: "images")
    end
  end

  def remove
    @image_upload = @parent.image_uploads.find(params[:id])
  end

  def destroy
    # Destroying an image upload actually removes the association
    # from the parent model. The parent model may implement versioning.
    @image_upload = @parent.image_uploads.find(params[:id])
    @parent.image_upload_ids.delete(@image_upload.id)
    @parent.save!

    flash[:success] = t(:image_removed)

    if @parent.is_a?(Investigation)
      destroy_audit_activity
      destroy_send_notification_email

      if params[:multiple]
        redirect_to new_investigation_image_upload_path(@parent, image_upload_id: params[:image_upload_id])
      else
        redirect_to investigation_images_path(@parent)
      end
    else
      redirect_to product_path(@parent, anchor: "images")
    end
  end

  def show
    @image_upload = @parent.image_uploads.find(params[:id]).decorate
    @parent = @parent.decorate
  end

private

  def set_and_authorise_parent
    @parent = get_parent
    authorize @parent, policy_class: ImageablePolicy
  end

  def get_parent
    if (pretty_id = params[:investigation_pretty_id] || params[:allegation_id] || params[:project_id] || params[:enquiry_id])
      return Investigation.find_by!(pretty_id:)
    end

    return Product.find(params[:product_id]) if params[:product_id]
    return Business.find(params[:business_id]) if params[:business_id]
  end

  def image_upload_params
    params.require(:image_upload).permit(:file_upload, :existing_file_upload_file_id)
  end

  def existing_file_from_id(existing_file_id)
    ActiveStorage::Blob.find_signed!(existing_file_id)
  end

  def create_audit_activity
    activity = AuditActivity::ImageUpload::Add.create!(
      metadata: AuditActivity::ImageUpload::Add.build_metadata(@image_upload.file_upload),
      added_by_user: current_user,
      investigation: @parent
    )

    activity.file_upload.attach(@image_upload.file_upload.blob)
  end

  def destroy_audit_activity
    activity = AuditActivity::ImageUpload::Destroy.create!(
      metadata: AuditActivity::ImageUpload::Destroy.build_metadata(@image_upload.file_upload),
      added_by_user: current_user,
      investigation: @parent
    )

    activity.file_upload.attach(@image_upload.file_upload.blob)
  end

  def create_send_notification_email
    return unless @parent.sends_notifications?

    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.notification_updated(
        @parent.pretty_id,
        recipient.name,
        recipient.email,
        "Image was attached to the notification by #{current_user&.decorate&.display_name(viewer: recipient)}.",
        "Notification updated"
      ).deliver_later
    end
  end

  def destroy_send_notification_email
    return unless @parent.sends_notifications?

    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.notification_updated(
        @parent.pretty_id,
        recipient.name,
        recipient.email,
        "Image attached to the notification was removed by #{current_user&.decorate&.display_name(viewer: recipient)}.",
        "Notification updated"
      ).deliver_later
    end
  end

  def email_recipients_for_case_owner
    investigation = @parent

    if investigation.owner_user && investigation.owner_user == current_user
      []
    elsif investigation.owner_user
      [investigation.owner_user]
    elsif investigation.owner_team && investigation.owner_team == current_user.team
      []
    elsif investigation.owner_team.email.present?
      [investigation.owner_team]
    else
      investigation.owner_team.users.active
    end
  end
end
