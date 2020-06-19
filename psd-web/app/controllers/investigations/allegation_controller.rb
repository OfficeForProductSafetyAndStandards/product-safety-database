class Investigations::AllegationController < Investigations::CreationFlowController
  set_attachment_names :attachment
  set_file_params_key :allegation

  steps :coronavirus, :complainant, :complainant_details, :allegation_details

private

  def model_key
    :allegation
  end

  def model_params
    %i[description hazard_type product_category coronavirus_related]
  end

  def set_investigation
    @investigation = Investigation::Allegation.new(investigation_params.merge(owner: current_user))
  end

  def success_message
    "Allegation was successfully created"
  end

  def set_page_title
    @page_title = "New allegation"
    @page_subtitle = "Who's making the allegation?"
  end
end
