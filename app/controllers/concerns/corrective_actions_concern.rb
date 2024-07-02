module CorrectiveActionsConcern
  extend ActiveSupport::Concern

  def corrective_action_params
    params.require(:corrective_action).permit(
      :investigation_product_id,
      :business_id,
      :action,
      :has_online_recall_information,
      :online_recall_information,
      :details,
      :related_file,
      :measure_type,
      :duration,
      :other_action,
      :further_corrective_action,
      :existing_document_file_id,
      legislation: [],
      geographic_scopes: [],
      file: %i[file description]
    ).with_defaults(legislation: [], geographic_scopes: []).merge("date_decided(1i)" => params[:corrective_action]["date_decided(1i)"]).merge("date_decided(2i)" => params[:corrective_action]["date_decided(2i)"]).merge("date_decided(3i)" => params[:corrective_action]["date_decided(3i)"])
  end
end
