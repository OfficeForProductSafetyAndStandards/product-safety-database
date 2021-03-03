class Investigations::EnquiryController < Investigations::CreationFlowController
  set_attachment_names :attachment
  set_file_params_key :enquiry

  steps :coronavirus, :about_enquiry, :complainant, :complainant_details, :enquiry_details

private

  def model_key
    :enquiry
  end

  def model_params
    [:user_title, :description, :received_type, :coronavirus_related, date_received: %i[day month year]]
  end

  def set_investigation
    @investigation = Investigation::Enquiry.new(investigation_params).build_owner_collaborations_from(current_user)
    set_notifying_country
  end

  def assign_type
    session[:enquiry][:received_type] = params[:enquiry][:received_type] == "other" ? params[:enquiry][:other_received_type] : params[:enquiry][:received_type]
  end

  def success_message
    "Enquiry was successfully created."
  end

  def set_page_title
    @page_title = "New enquiry"
    @page_subtitle = "Who did the enquiry come from?"
  end
end
