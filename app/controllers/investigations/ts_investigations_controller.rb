class Investigations::TsInvestigationsController < ApplicationController
  include Wicked::Wizard

  steps :reason_for_creating,
        :reason_for_concern,
        :reference_number,
        :case_name,
        :case_created

  before_action :redirect_to_first_step_if_wizard_not_started, if: -> { step && (step != :reason_for_creating) }

  def show
    case step
    when :reason_for_creating
      @reason_for_creating_form = if session.dig(:form_answers, :case_is_safe)
                                    ReasonForCreatingForm.new(case_is_safe: session[:form_answers][:case_is_safe])
                                  else
                                    ReasonForCreatingForm.new
                                  end
      @product = authorize_product
    when :reason_for_concern
      skip_step if session[:investigation].reported_reason == "safe_and_compliant"
      @edit_why_reporting_form = EditWhyReportingForm.new
    when :reference_number
      @reference_number_form = if session.dig(:form_answers, :has_complainant_reference)
                                 ReferenceNumberForm.new(has_complainant_reference: session[:form_answers][:has_complainant_reference], complainant_reference: session[:investigation].try(:complainant_reference))
                               else
                                 ReferenceNumberForm.new
                               end
    when :case_name
      @case_name_form = CaseNameForm.new
      @product = authorize_product
    when :case_created
      @investigation = session[:investigation]
      @product = authorize_product
      @investigation.build_owner_collaborations_from(current_user)
      prism_risk_assessment = PrismRiskAssessment.find(session[:prism_risk_assessment_id]) if session[:prism_risk_assessment_id].present?
      CreateCase.call(investigation: session[:investigation], user: current_user, product: Product.find(session[:product_id]), prism_risk_assessment:)
      clear_session
    end

    render_wizard
  end

  def new
    clear_session
    session[:product_id] = params[:product_id]
    session[:prism_risk_assessment_id] = params[:prism_risk_assessment_id]
    authorize_product
    redirect_to wizard_path(steps.first)
  end

  def update
    case step
    when :reason_for_creating
      @reason_for_creating_form = ReasonForCreatingForm.new(reason_for_creating_params)
      @product = authorize_product
      return render_wizard unless @reason_for_creating_form.valid?

      if @reason_for_creating_form.case_is_safe == "yes"
        session[:investigation] = Investigation::Case.new(reported_reason: "safe_and_compliant")
        skip_step
      else
        session[:investigation] = Investigation::Case.new
      end
      session[:form_answers] = reason_for_creating_params
    when :reason_for_concern
      reported_reason = calculate_reported_reason(reason_for_concern_params)
      @edit_why_reporting_form = EditWhyReportingForm.new(reason_for_concern_params.merge(reported_reason:))
      return render_wizard unless @edit_why_reporting_form.valid?

      session[:investigation] = Investigation::Case.new(reported_reason:, hazard_description: @edit_why_reporting_form.hazard_description,
                                                        hazard_type: @edit_why_reporting_form.hazard_type, non_compliant_reason: @edit_why_reporting_form.non_compliant_reason)
      session[:form_answers].merge!(reason_for_creating_params)
    when :reference_number
      @reference_number_form = ReferenceNumberForm.new(reference_number_params)
      return render_wizard unless @reference_number_form.valid?

      session[:investigation].assign_attributes(complainant_reference: @reference_number_form.complainant_reference) if @reference_number_form.has_complainant_reference
      session[:form_answers].merge!(reference_number_params)
    when :case_name
      @case_name_form = CaseNameForm.new(case_name_params.merge(current_user:))
      @product = authorize_product
      return render_wizard unless @case_name_form.valid?

      session[:investigation].assign_attributes(user_title: @case_name_form.user_title)
    end
    redirect_to next_wizard_path
  end

private

  def authorize_product
    return if session[:product_id].blank?

    product = Product.find session[:product_id]
    authorize product, :can_spawn_case?
    product
  end

  def calculate_reported_reason(reason_for_concern_params)
    return "unsafe_and_non_compliant" if reason_for_concern_params["reported_reason_unsafe"] && reason_for_concern_params["reported_reason_non_compliant"]
    return "unsafe"                   if reason_for_concern_params["reported_reason_unsafe"]
    return "non_compliant"            if reason_for_concern_params["reported_reason_non_compliant"]
  end

  def clear_session
    session.delete :form_answers
    session.delete :investigation
    session.delete :prism_risk_assessment_id
    session.delete :product_id
  end

  def redirect_to_first_step_if_wizard_not_started
    redirect_to action: :new unless session[:investigation]
  end

  def reason_for_creating_params
    return {} unless params[:investigation]

    params.require(:investigation).permit(:case_is_safe, :product_id)
  end

  def reason_for_concern_params
    params.require(:investigation).permit(:hazard_type, :hazard_description, :reported_reason_non_compliant, :reported_reason_unsafe, :non_compliant_reason)
  end

  def reference_number_params
    params.require(:investigation).permit(:has_complainant_reference, :complainant_reference)
  end

  def case_name_params
    params.require(:investigation).permit(:user_title)
  end

  def assign_safety_and_compliance_attributes(reported_reason:, hazard_description:, hazard_type:, non_compliant_reason:)
    if reported_reason.to_s == "safe_and_compliant"
      session[:investigation] = investigation.assign_attributes(hazard_description: nil, hazard_type: nil, non_compliant_reason: nil, reported_reason:)
    end

    if reported_reason.to_s == "unsafe_and_non_compliant"
      session[:investigation] = investigation.assign_attributes(hazard_description:, hazard_type:, non_compliant_reason:, reported_reason:)
    end

    if reported_reason.to_s == "unsafe"
      session[:investigation] = investigation.assign_attributes(hazard_description:, hazard_type:, non_compliant_reason: nil, reported_reason:)
    end

    if reported_reason.to_s == "non_compliant"
      session[:investigation] = investigation.assign_attributes(hazard_description: nil, hazard_type: nil, non_compliant_reason:, reported_reason:)
    end
  end
end
