module CorrectiveActionConcern
  extend ActiveSupport::Concern

  def corrective_action_params
    return {} if params[:corrective_action].blank?

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
      file: %i[file description],
      date_decided: %i[day month year]
    )
  end
end
