module Investigations
  class SupportingInformationController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_investigation_non_protected_details
    before_action :set_investigation_breadcrumbs

    def index
      @grouped_supporting_information = {
        "Accident or incidents" => {
          items: @investigation.unexpected_events.order(created_at: :desc).map(&:decorate),
          new_path: new_investigation_accident_or_incidents_type_path(@investigation)
        },
        "Corrective actions" => {
          items: @investigation.corrective_actions.order(created_at: :desc).map(&:decorate),
          new_path: new_investigation_corrective_action_path(@investigation)
        },
        "Risk assessments" => {
          items: @investigation.risk_assessments.order(created_at: :desc).map(&:decorate),
          new_path: new_investigation_risk_assessment_path(@investigation)
        },
        "PRISM risk assessments" => {
          items: @investigation.prism_risk_assessments.order(created_at: :desc).map(&:decorate),
          new_path: new_investigation_prism_risk_assessment_path(@investigation)
        },
        "Correspondence" => {
          items: @investigation.correspondences.order(created_at: :desc).map(&:decorate),
          new_path: new_investigation_correspondence_path(@investigation)
        },
        "Test results" => {
          items: @investigation.test_results.order(created_at: :desc).map(&:decorate),
          new_path: new_investigation_funding_source_path(@investigation)
        },
        "Other" => {
          items: @investigation.generic_supporting_information_attachments.order(created_at: :desc).map(&:decorate),
          new_path: new_investigation_document_path(@investigation)
        }
      }
    end
  end
end
