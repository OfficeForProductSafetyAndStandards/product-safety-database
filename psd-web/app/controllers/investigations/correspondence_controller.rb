# This class serves as as a common base controller extended by the different types of correspondence
class Investigations::CorrespondenceController < ApplicationController
  include FileConcern
  include Wicked::Wizard
  steps :context, :content, :confirmation

  before_action :set_investigation
  before_action :set_correspondence, only: %i[show update create]
  before_action :set_attachments, only: %i[show update create]
  before_action :store_correspondence, only: %i[update]

  def new
    correspondence_form
    return unless params[:commit] == "Continue" && correspondence_form.valid?

    case correspondence_form.type
    when "email"
      redirect_to new_investigation_email_path(@investigation)
    when "meeting"
      redirect_to new_investigation_meeting_path(@investigation)
    when "phone_call"
      redirect_to new_investigation_phone_call_path(@investigation)
    end
  end

  def create
    update_attachments
    if correspondence_valid? && @investigation.save
      attach_files
      save_attachments
      audit_class.from(@correspondence, @investigation)
      redirect_to investigation_path(@investigation), flash: { success: "Correspondence was successfully recorded" }
    else
      Rails.logger.error "Cannot create correspondence because investigation has errors: #{@investigation.errors.full_messages}" unless @investigation.valid?
      redirect_to investigation_path(@investigation), flash: { warning: "Correspondence could not be saved." }
    end
  end

  def show
    render_wizard
  end

  def update
    update_attachments
    if correspondence_valid?
      save_attachments
      redirect_to next_wizard_path
    else
      render step
    end
  end

private

  def clear_session
    session[correspondence_params_key] = nil
  end

  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?
    @investigation = investigation.decorate
  end

  def set_correspondence
    @correspondence = model_class.new correspondence_params
    @correspondence.set_dates_from_params(params[correspondence_params_key])
    @investigation.association(:correspondences).add_to_target(@correspondence)
  end

  def store_correspondence
    session[correspondence_params_key] = @correspondence.attributes if @correspondence.valid?(step)
  end

  def correspondence_params
    session_params.merge(request_params)
  end

  def session_params
    session[correspondence_params_key] || {}
  end

  def correspondence_params_key
    # Turns the class name into the same format used by rails in form `name` attributes (e.g. 'correspondence_email')
    model_class.name.underscore.tr("/", "_")
  end

  def correspondence_form
    @correspondence_form ||= CorrespondenceForm.new(type: params[:type])
  end
end
