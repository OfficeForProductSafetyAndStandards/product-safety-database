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
    else
      file = ActiveStorage::Blob.create_and_upload!(
        io: document_upload_params[:file_upload],
        filename: document_upload_params[:file_upload].original_filename,
        content_type: document_upload_params[:file_upload].content_type
      )
      @document_upload = DocumentUpload.new(
        document_upload_params.merge(
          file_upload: file, existing_file_upload_file_id: file.signed_id, upload_model: @parent, created_by: current_user.id
        )
      )
    end

    # sleep to give the antivirus checks a chance to be completed before running document form validations
    sleep 3

    if @document_upload.valid?
      @document_upload.save
      # Manually attach the document upload to its parent model's ID array
      @parent.document_upload_ids.push(@document_upload.id)
      @parent.save
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

    return redirect_to(product_path(@parent, anchor: "images")) if is_a_product_image?
    return redirect_to(product_path(@parent, anchor: "attachments")) if is_a_product_file?
    return redirect_to(business_path(@parent, anchor: "attachments")) if is_a_business_file?
    return redirect_to(@parent) unless @parent.is_a?(Investigation)
    return redirect_to investigation_images_path(@parent) if @document_upload.file_upload.image?

    redirect_to investigation_supporting_information_index_path(@parent)
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
      @document_upload.save
      # Manually attach the document upload to its parent model's ID array
      # and remove the old document upload
      @parent.document_upload_ids.push(@document_upload.id).delete(old_document_upload.id)
      @parent.save
    else
      @parent = @parent.decorate
      return render :edit
    end

    flash[:success] = @document_upload.file_upload.image? ? t(:image_updated) : t(:file_updated, type: @parent.model_name.human.downcase)

    return redirect_to(product_path(@parent, anchor: "images")) if is_a_product_image?
    return redirect_to(product_path(@parent, anchor: "attachments")) if is_a_product_file?
    return redirect_to(business_path(@parent, anchor: "attachments")) if is_a_business_file?
    return redirect_to(@parent) unless @parent.is_a?(Investigation)
    return redirect_to investigation_images_path(@parent) if @document_upload.file_upload.image?

    redirect_to investigation_supporting_information_index_path(@parent)
  end

  def remove
    @document_upload = @parent.document_uploads.find(params[:id])
  end

  # DELETE /document_uploads/1
  def destroy
    @document_upload = @parent.document_uploads.find(params[:id])
    @document_upload.destroy

    flash[:success] = @document_upload.file_upload.image? ? t(:image_removed) : t(:file_removed)

    return redirect_to(@parent) unless @parent.is_a?(Investigation)
    return redirect_to investigation_images_path(@parent) if @document_upload.file_upload.image?

    redirect_to investigation_supporting_information_index_path(@parent)
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
    if (pretty_id = params[:investigation_pretty_id] || params[:allegation_id] || params[:project_id] || params[:enquiry_id])
      return Investigation.find_by!(pretty_id:)
    end

    return Product.find(params[:product_id]) if params[:product_id]
    return Business.find(params[:business_id]) if params[:business_id]
  end

  def document_upload_params
    params.require(:document_upload).permit(:file_upload, :existing_file_upload_file_id, :title, :description)
  end

  def existing_file_from_id(existing_file_id)
    ActiveStorage::Blob.find_signed!(existing_file_id)
  end

  def is_a_product_image?
    @parent.is_a?(Product) && @document_upload.file_upload.image?
  end

  def is_a_business_file?
    @parent.is_a?(Business)
  end

  def is_a_product_file?
    @parent.is_a?(Product) && !@document_upload.file_upload.image?
  end
end
