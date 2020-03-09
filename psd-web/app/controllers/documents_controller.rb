class DocumentsController < ApplicationController
  include FileConcern
  set_attachment_names :file
  set_file_params_key :document

  include DocumentsHelper
  include GdprHelper

  before_action :set_parent
  before_action :set_file, only: %i[edit update remove destroy]

  # GET /documents/1/edit
  def edit; end

  # PATCH/PUT /documents/1
  def update
    previous_data = {
      title: @file.metadata[:title],
      description: @file.metadata[:description]
    }
    update_blob_metadata(@file.blob, get_attachment_metadata_params(:file))

    return render :edit unless file_valid?

    @file.blob.save
    return redirect_to @parent unless @parent.is_a? Investigation

    AuditActivity::Document::Update.from(@file.blob, @parent, previous_data)
    redirect_to investigation_path(@parent)
  end

  def remove; end

  # DELETE /documents/1
  def destroy
    @file.destroy
    return redirect_to @parent, flash: { success: "File was successfully removed" } unless @parent.is_a? Investigation

    AuditActivity::Document::Destroy.from(@file.blob, @parent)
    redirect_to investigation_path(@parent), flash: { success: "File was successfully removed" }
  end

private

  def set_file
    @errors = ActiveModel::Errors.new(ActiveStorage::Blob.new)
    @file = file_collection.find(params[:id]) if params[:id].present?
    raise Pundit::NotAuthorizedError unless can_be_displayed?(@file, @parent)
  end

  def file_valid?
    if @file.blank? || @file.blob.blank?
      @errors.add(:base, :file_not_implemented, message: "File cannot be blank")
    end
    if @file.metadata[:title].blank?
      @errors.add(:base, :title_not_implemented, message: "Title cannot be blank")
    end
    validate_blob_size(@file, @errors, "file")
    @errors.empty?
  end
end
