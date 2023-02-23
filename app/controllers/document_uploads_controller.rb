class DocumentUploadsController < ApplicationController
  include DocumentUploadsHelper

  before_action :set_and_authorise_parent

  def new
    @document_upload = DocumentUpload.new(upload_model: @parent)
    @parent = @parent.decorate
  end

  def create
    if document_upload_params[:existing_file_upload_file_id].present? && document_upload_params[:file_upload].blank?
      existing_file = existing_file_from_id(document_upload_params[:existing_file_upload_file_id])
      @document_upload = DocumentUpload.new(
        document_upload_params.merge(
          file_upload: existing_file, upload_model: @parent, created_by: current_user.id
        )
      )
    elsif document_upload_params[:file_upload].present?
      file = ActiveStorage::Blob.create_and_upload!(
        io: document_upload_params[:file_upload],
        filename: document_upload_params[:file_upload].original_filename,
        content_type: document_upload_params[:file_upload].content_type
      )
      file.analyze_later
      @document_upload = DocumentUpload.new(
        document_upload_params.merge(
          file_upload: file, existing_file_upload_file_id: file.signed_id, upload_model: @parent, created_by: current_user.id
        )
      )
    else
      # The document upload won't be valid since there is no file
      @document_upload = DocumentUpload.new(document_upload_params.merge(upload_model: @parent, created_by: current_user.id))
    end

    # sleep to give the antivirus checks a chance to be completed before running document form validations
    sleep 3

    if @document_upload.valid?
      @document_upload.save!
      # Manually attach the document upload to its parent model's ID array
      @parent.document_upload_ids.push(@document_upload.id)
      @parent.save!
    else
      @parent = @parent.decorate
      return render :new
    end

    # Reload the uploaded file to get the latest metadata
    @document_upload.file_upload.try(:reload)

    if @document_upload.file_upload.metadata["safe"] && @document_upload.file_upload.metadata["analyzed"]
      flash[:success] = @document_upload.file_upload.image? ? t(:image_added) : t(:file_added, type: @parent.model_name.human.downcase)
    else
      file_type = @document_upload.file_upload.image? ? "image" : "file"
      flash[:information] = "The #{file_type} did not finish uploading - you must refresh the #{file_type}"
    end

    redirect_to(product_path(@parent, anchor: "images"))
  end

  # GET /document_uploads/1/edit
  def edit
    @document_upload = @parent.document_uploads.find(params[:id])
    @parent = @parent.decorate
  end

  # PATCH/PUT /document_uploads/1
  def update
    # Updating a document upload actually creates a new upload and replaces the association
    # on the parent model. The parent model may implement versioning.
    old_document_upload = @parent.document_uploads.find(params[:id])
    @document_upload = DocumentUpload.new(
      document_upload_params.merge(
        file_upload: old_document_upload.file_upload.blob, upload_model: @parent, created_by: current_user.id
      )
    )

    if @document_upload.valid?
      @document_upload.save!
      # Manually attach the document upload to its parent model's ID array
      # and remove the old document upload
      @parent.document_upload_ids.push(@document_upload.id).delete(old_document_upload.id)
      @parent.save!
    else
      @parent = @parent.decorate
      return render :edit
    end

    flash[:success] = @document_upload.file_upload.image? ? t(:image_updated) : t(:file_updated, type: @parent.model_name.human.downcase)

    redirect_to(product_path(@parent, anchor: "images"))
  end

  def remove
    @document_upload = @parent.document_uploads.find(params[:id])
  end

  # DELETE /document_uploads/1
  def destroy
    # Destroying a document upload actually removes the association
    # from the parent model. The parent model may implement versioning.
    @document_upload = @parent.document_uploads.find(params[:id])
    @parent.document_upload_ids.delete(@document_upload.id)
    @parent.save!

    flash[:success] = @document_upload.file_upload.image? ? t(:image_removed) : t(:file_removed)

    redirect_to(@parent)
  end

  def show
    @document_upload = @parent.document_uploads.find(params[:id]).decorate
    @parent = @parent.decorate
  end

private

  def set_and_authorise_parent
    @parent = get_parent
    authorize @parent, policy_class: DocumentablePolicy
  end

  def get_parent
    Product.find(params[:product_id])
  end

  def document_upload_params
    params.require(:document_upload).permit(:file_upload, :existing_file_upload_file_id, :title, :description)
  end

  def existing_file_from_id(existing_file_id)
    ActiveStorage::Blob.find_signed!(existing_file_id)
  end
end
