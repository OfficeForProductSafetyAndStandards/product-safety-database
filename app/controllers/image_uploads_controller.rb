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

    if @image_upload.file_upload.metadata["safe"] && @image_upload.file_upload.metadata["analyzed"]
      flash[:success] = t(:image_added)
    else
      flash[:information] = "The image did not finish uploading - you must refresh the image"
    end

    redirect_to(product_path(@parent, anchor: "images"))
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

    redirect_to(@parent)
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
    Product.find(params[:product_id])
  end

  def image_upload_params
    params.require(:image_upload).permit(:file_upload, :existing_file_upload_file_id)
  end

  def existing_file_from_id(existing_file_id)
    ActiveStorage::Blob.find_signed!(existing_file_id)
  end
end
