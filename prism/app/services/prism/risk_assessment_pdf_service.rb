module Prism
  class RiskAssessmentPdfService
    include Prism::Tasks::CreateHelper
    include Prism::Tasks::EvaluateHelper

    attr_reader :prism_risk_assessment, :harm_scenarios, :file

    def initialize(prism_risk_assessment, file)
      @prism_risk_assessment = prism_risk_assessment
      @harm_scenarios = prism_risk_assessment.harm_scenarios
      @file = file
    end

    def self.generate_pdf(prism_risk_assessment, file)
      new(prism_risk_assessment, file).generate_pdf
    end

    def generate_pdf
      metadata = {
        Title: "OPSS - PRISM risk assessment - #{prism_risk_assessment.name}",
        Author: prism_risk_assessment.user.name,
        Subject: "#{prism_risk_assessment.name} risk assessment",
        Creator: "Product Safety Database",
        Producer: "Prawn",
        CreationDate: Time.zone.now
      }
      pdf = Prawn::Document.new(page_size: "A4", info: metadata)
      # rubocop:disable Rails/SaveBang
      pdf.font_families.update(
        "GDS Transport" => {
          normal: { file: Prism::Engine.root.join("app/assets/fonts/prism/gds-transport-light.ttf"), font: "GDSTransport" },
          bold: { file: Prism::Engine.root.join("app/assets/fonts/prism/gds-transport-bold.ttf"), font: "GDSTransport-Bold" },
        }
      )
      # rubocop:enable Rails/SaveBang
      pdf.font("GDS Transport")
      pdf.table([
        [
          { image: File.open(Prism::Engine.root.join("app/assets/images/prism/opss-logo.jpg")), fit: [200, 200] },
          prism_risk_assessment.product.virus_free_images.present? ? prism_risk_assessment.product.virus_free_images.first.file_upload.blob.open { |file| { image: File.open(file.path), fit: [200, 200], position: :right } } : ""
        ],
      ], width: 522, cell_style: { borders: [] })
      pdf.text "About assessment", color: "000000", style: :bold, size: 20
      pdf.move_down 10
      pdf.table([
        [{ content: "Assessment name", font_style: :bold }, prism_risk_assessment.name],
        [{ content: "Name of assessor", font_style: :bold }, prism_risk_assessment.assessor_name],
        [{ content: "Name of assessment organisation", font_style: :bold }, prism_risk_assessment.assessment_organisation],
      ], width: 522, column_widths: { 0 => 200 })
      pdf.move_down 20
      pdf.text "Product details", color: "000000", style: :bold, size: 20
      pdf.text "as recorded on the PSD", color: "000000", size: 15
      pdf.move_down 10
      pdf.table([
        [{ content: "PSD reference", font_style: :bold }, "<link href=\"#{Rails.application.routes.url_helpers.product_url(prism_risk_assessment.product, host: ENV.fetch('PSD_HOST', 'localhost'), port: Rails.env.production? ? 80 : ENV.fetch('PORT', 3000))}\"><u>#{prism_risk_assessment.product.psd_ref}</u></link>"],
        [{ content: "Product", font_style: :bold }, prism_risk_assessment.product.name],
        [{ content: "Brand name", font_style: :bold }, prism_risk_assessment.product.brand],
        [{ content: "Description", font_style: :bold }, prism_risk_assessment.product.description],
        [{ content: "Country of origin", font_style: :bold }, country_from_code(prism_risk_assessment.product.country_of_origin)],
        [{ content: "Counterfeit", font_style: :bold }, counterfeit(prism_risk_assessment.product.authenticity)],
      ], width: 522, column_widths: { 0 => 200 }, cell_style: { inline_format: true })
      if prism_risk_assessment.normal_risk?
        pdf.move_down 20
        pdf.text "Product sales and safety", color: "000000", style: :bold, size: 20
        pdf.move_down 10
        pdf.table([
          [{ content: "Name of the business that sold the product", font_style: :bold }, prism_risk_assessment.product_market_detail.selling_organisation],
          [{ content: "Estimated number of products in use", font_style: :bold }, ActiveSupport::NumberHelper.number_to_delimited(prism_risk_assessment.product_market_detail.total_products_sold)],
          [{ content: "Applicable product safety legislation and standards", font_style: :bold }, prism_risk_assessment.product_market_detail.safety_legislation_standards.join("\n")],
        ], width: 522, column_widths: { 0 => 200 })
        pdf.move_down 20
        pdf.text "Product hazards", color: "000000", style: :bold, size: 20
        pdf.move_down 10
        pdf.table([
          [{ content: "Number of hazards", font_style: :bold }, evaluation_translate_simple("number_of_hazards", prism_risk_assessment.product_hazard.number_of_hazards)],
        ], width: 522, column_widths: { 0 => 200 })
        pdf.start_new_page
        pdf.text "Harm scenarios", color: "000000", style: :bold, size: 20
        prism_risk_assessment.harm_scenarios.each_with_index do |harm_scenario, index|
          pdf.move_down 10
          pdf.text "Scenario #{index + 1}", color: "000000", style: :bold, size: 15
          pdf.move_down 10
          pdf.table([
            [{ content: "Hazard type", font_style: :bold }, harm_scenario_hazard_type(harm_scenario.hazard_type)],
            [{ content: "Hazard description", font_style: :bold }, harm_scenario.description],
            [{ content: "Affected users", font_style: :bold }, harm_scenario_product_aimed_at(harm_scenario.product_aimed_at, harm_scenario.product_aimed_at_description)],
            [{ content: "Other users that may be at risk", font_style: :bold }, harm_scenario_unintended_risks_for(harm_scenario.unintended_risks_for)],
            *harm_scenario.harm_scenario_steps.each_with_index.map do |hss, hss_index|
              # rubocop:disable Style/StringConcatenation
              [{ content: "Step #{hss_index + 1}", font_style: :bold }, "#{hss.description}\n\nProbability of harm: #{hss.probability_decimal || '1 in ' + ActiveSupport::NumberHelper.number_to_delimited(hss.probability_frequency.to_s)}\n\nSupporting information: #{harm_scenario_probability_evidence(hss.probability_evidence)}"]
              # rubocop:enable Style/StringConcatenation
            end,
            [{ content: "Severity level", font_style: :bold }, "#{harm_scenario_severity_level(harm_scenario.severity)}\n#{harm_scenario_multiple_casualties(harm_scenario.multiple_casualties)}"],
            [{ content: "Overall probability of harm", font_style: :bold }, harm_scenario_overall_probability_of_harm(harm_scenario).risk_level.capitalize],
          ], width: 522, column_widths: { 0 => 200 })
        end
        pdf.move_down 20
        pdf.text "Overall product risk level", color: "000000", style: :bold, size: 20
        pdf.move_down 10
        pdf.table([
          [{ content: "Risk level", font_style: :bold }, overall_product_risk_level.risk_level.capitalize],
        ], width: 522, column_widths: { 0 => 200 })
      end
      pdf.start_new_page
      pdf.text "Level of uncertainty and sensitivity analysis", color: "000000", style: :bold, size: 20
      pdf.move_down 10
      pdf.table([
        [{ content: "Level of uncertainty associated with the risk assessment", font_style: :bold }, evaluation_translate_simple("level_of_uncertainty", prism_risk_assessment.evaluation.level_of_uncertainty)],
        [{ content: "Has sensitivity analysis been undertaken?", font_style: :bold }, evaluation_translate_simple("yes_no", prism_risk_assessment.evaluation.sensitivity_analysis)],
      ], width: 522, column_widths: { 0 => 200 })
      pdf.move_down 20
      pdf.text "Risk evaluation", color: "000000", style: :bold, size: 20
      pdf.text "Nature of risk", color: "000000", style: :bold, size: 15
      pdf.move_down 10
      pdf.table([
        [{ content: "What other types of harm could the hazard cause?", font_style: :bold }, other_types_of_harm(prism_risk_assessment.evaluation.other_types_of_harm)],
        [{ content: "Is the number of products estimated to be in use expected to change?", font_style: :bold }, evaluation_translate_simple("number_of_products_expected_to_change", @prism_risk_assessment.evaluation.number_of_products_expected_to_change)],
        [{ content: "Does the uncertainty level have implications for risk management decisions?", font_style: :bold }, evaluation_translate_simple("yes_no", @prism_risk_assessment.evaluation.uncertainty_level_implications_for_risk_management)],
        [{ content: "How does the risk level compare to that of comparable products?", font_style: :bold }, evaluation_translate_simple("comparable_risk_level", @prism_risk_assessment.evaluation.comparable_risk_level)],
        [{ content: "Is there potential for multiple casualties in a single incident?", font_style: :bold }, evaluation_translate_simple("yes_no", @prism_risk_assessment.evaluation.multiple_casualties)],
        [{ content: "Is there a significant risk differential?", font_style: :bold }, evaluation_translate_simple("yes_no", @prism_risk_assessment.evaluation.significant_risk_differential)],
        [{ content: "Are there people at increased risk?", font_style: :bold }, evaluation_translate_simple("yes_no", @prism_risk_assessment.evaluation.people_at_increased_risk)],
        [{ content: "Is relevant action planned or underway by another MSA or other organisation?", font_style: :bold }, evaluation_translate_simple("yes_no", @prism_risk_assessment.evaluation.relevant_action_by_others)],
        [{ content: "As regards the nature of the risk, are there factors to take account of in relation to risk management decisions?", font_style: :bold }, evaluation_translate_simple("yes_no", @prism_risk_assessment.evaluation.factors_to_take_into_account)],
      ], width: 522, column_widths: { 0 => 200 })
      pdf.move_down 10
      pdf.text "Perception and tolerability of risk", color: "000000", style: :bold, size: 15
      pdf.move_down 10
      pdf.table([
        [{ content: "As well as the hazard associated with the non-compliance, does the product have any other hazards that can and do cause harm?", font_style: :bold }, evaluation_translate_simple("yes_no", @prism_risk_assessment.evaluation.other_hazards)],
        [{ content: "Is this a low likelihood but high severity risk?", font_style: :bold }, evaluation_translate_simple("yes_no", @prism_risk_assessment.evaluation.low_likelihood_high_severity)],
        [{ content: "Is there a risk to non-users?", font_style: :bold }, evaluation_translate_simple("yes_no", @prism_risk_assessment.evaluation.risk_to_non_users)],
        [{ content: "Is this a type of product aimed at vulnerable users?", font_style: :bold }, evaluation_translate_simple("yes_no", @prism_risk_assessment.evaluation.aimed_at_vulnerable_users)],
        [{ content: "Is the product designed to provide a protective function?", font_style: :bold }, evaluation_translate_simple("yes_no", @prism_risk_assessment.evaluation.designed_to_provide_protective_function)],
        [{ content: "Can users exert any control over the risk?", font_style: :bold }, evaluation_translate_simple("yes_no", @prism_risk_assessment.evaluation.user_control_over_risk)],
        [{ content: "Are there other matters that will influence the way the risk is perceived?", font_style: :bold }, other_risk_perception_matters(@prism_risk_assessment.evaluation.other_risk_perception_matters)],
      ], width: 522, column_widths: { 0 => 200 })
      pdf.move_down 20
      pdf.text "Risk evaluation outcome", color: "000000", style: :bold, size: 20
      pdf.move_down 10
      pdf.table([
        [{ content: "How would you describe the risk presented by the product?", font_style: :bold }, evaluation_translate_simple("risk_tolerability", @prism_risk_assessment.evaluation.risk_tolerability)],
      ], width: 522, column_widths: { 0 => 200 })
      pdf.render(file)
    end
  end
end
