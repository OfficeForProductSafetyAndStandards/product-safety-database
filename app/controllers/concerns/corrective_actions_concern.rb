module CorrectiveActionsConcern
  extend ActiveSupport::Concern

  def corrective_action_params
    params.require(:corrective_action).permit(
      :product_id,
      :business_id,
      :legislation,
      :action,
      :has_online_recall_information,
      :online_recall_information,
      :details,
      :related_file,
      :measure_type,
      :duration,
      :geographic_scope,
      :other_action,
      :further_corrective_action,
      :existing_document_file_id,
      file: %i[file description],
      date_decided: %i[day month year]
    )
  end
end
