class DocumentsController < ApplicationController
  include DocumentsHelper

  before_action :set_and_authorise_parent

  def new
    @document_form = DocumentForm.new
    @parent = @parent.decorate
  end

  def create
    @document_form = DocumentForm.new(document_params)
    @document_form.cache_file!(current_user)

    unless @document_form.valid?
      @parent = @parent.decorate
      return render :new
    end

    AddDocument.call!(@document_form.attributes.except("existing_document_file_id").merge({
      parent: @parent,
      user: current_user,
    }))

    # Reload the uploaded file to get the latest metadata for virus status
    @document_form.document.try(:reload)
    file_type = @document_form.document.image? ? "image" : "file"
    attachment = @parent.documents.find_by(blob_id: @document_form.document)

    if attachment&.safe?
      # File has been checked for viruses and is safe
      flash[:success] = @document_form.document.image? ? t(:image_added) : t(:file_added, type: @parent.model_name.human.downcase)
    elsif attachment&.virus?
      # File has been checked for viruses and is infected
      flash[:warning] = "The #{file_type} is infected with a virus and will be deleted - please upload again"
    else
      # File has not yet been checked for viruses
      flash[:information] = "The #{file_type} has not yet been checked for viruses - refresh the page for an update"
    end

    return redirect_to(product_path(@parent, anchor: "images")) if is_a_product_image?
    return redirect_to(product_path(@parent, anchor: "attachments")) if is_a_product_file?
    return redirect_to(business_path(@parent, anchor: "attachments")) if is_a_business_file?
    return redirect_to(@parent) unless @parent.is_a?(Investigation)
    return redirect_to investigation_images_path(@parent) if @document_form.document.image?

    redirect_to investigation_supporting_information_index_path(@parent)
  end

  # GET /documents/1/edit
  def edit
    @file = @parent.documents.find(params[:id])
    @document_form = DocumentForm.from(@file)
    @parent = @parent.decorate
  end

  # PATCH/PUT /documents/1
  def update
    @file = @parent.documents.find(params[:id])

    @document_form = DocumentForm.from(@file)
    @document_form.assign_attributes(document_params)

    unless @document_form.valid?
      @parent = @parent.decorate
      return render :edit
    end

    UpdateDocument.call!(@document_form.attributes.slice("title", "description").merge({
      parent: @parent,
      file: @file.blob,
      user: current_user,
    }))

    flash[:success] = @document_form.document.image? ? t(:image_updated) : t(:file_updated)

    return redirect_to(@parent) unless @parent.is_a?(Investigation)
    return redirect_to investigation_images_path(@parent) if @document_form.document.image?

    redirect_to investigation_supporting_information_index_path(@parent)
  end

  def remove
    @file = @parent.documents.find(params[:id])
  end

  # DELETE /documents/1
  def destroy
    @file = @parent.documents.find(params[:id])

    DeleteDocument.call!(
      document: @file,
      parent: @parent,
      user: current_user
    )

    flash[:success] = @file.image? ? t(:image_removed) : t(:file_removed)

    return redirect_to(@parent) unless @parent.is_a?(Investigation)
    return redirect_to investigation_images_path(@parent) if @file.image?

    redirect_to investigation_supporting_information_index_path(@parent)
  end

  def show
    @file = @parent.documents.find(params[:id]).decorate
    @parent = @parent.decorate
  end

private

  def set_and_authorise_parent
    @parent = get_parent
    authorize @parent, policy_class: DocumentablePolicy
  end

  def document_params
    params.require(:document).permit(:existing_document_file_id, :document, :title, :description)
  end

  def get_parent
    if (pretty_id = params[:investigation_pretty_id] || params[:allegation_id] || params[:project_id] || params[:enquiry_id])
      return Investigation.find_by!(pretty_id:)
    end

    return Product.find(params[:product_id]) if params[:product_id]

    Business.find(params[:business_id]) if params[:business_id]
  end

  def is_a_product_image?
    @parent.is_a?(Product) && @document_form.document.image?
  end

  def is_a_business_file?
    @parent.is_a?(Business)
  end

  def is_a_product_file?
    @parent.is_a?(Product) && !@document_form.document.image?
  end
end
