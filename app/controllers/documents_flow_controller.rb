class DocumentsFlowController < ApplicationController
  include FileConcern
  set_attachment_names :file
  set_file_params_key :document

  include DocumentsHelper
  include Wicked::Wizard
  steps :upload, :metadata

  before_action :set_parent
  before_action :authorize_if_attached_to_investigation
  before_action :set_file, only: %i[show update]

  def show
    render_wizard
  end

  def new
    initialize_file_attachments
    redirect_to wizard_path(steps.first, request.query_parameters)
  end

  def update
    update_blob_metadata(@file_blob, get_attachment_metadata_params(:file))
    return render step unless file_valid?

    @file_blob.save
    return redirect_to next_wizard_path unless step == steps.last

    attach_blobs_to_list(@file_blob, file_collection)

    return redirect_to(@parent) unless @parent.is_a?(Investigation)

    AuditActivity::Document::Add.from(@file_blob, @parent)
    if @file_blob.image?
      redirect_to investigation_images_path(@parent)
    else
      redirect_to investigation_supporting_information_index_path(@parent)
    end
  end

private

  def authorize_if_attached_to_investigation
    authorize @parent, :update? if @parent.is_a? Investigation
  end

  def set_file
    @errors = ActiveModel::Errors.new(ActiveStorage::Blob.new)
    @file_blob, * = load_file_attachments
  end

  def file_valid?
    if @file_blob.blank? && step == :upload
      @errors.add(:base, :file_not_implemented, message: "Enter file")
    end
    if @file_blob && @file_blob.metadata[:title].blank? && step != :upload
      @errors.add(:base, :title_not_implemented, message: "Enter title")
    end
    validate_blob_size(@file_blob, @errors, "file") if step == :upload
    @errors.empty?
  end
end
