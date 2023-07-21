# Define wizard steps for normal and serious risk pathways split by section
NORMAL_RISK_DEFINE_STEPS = %i[
  add_assessment_details search_or_add_a_new_product add_details_about_products_in_use_and_safety
].freeze
NORMAL_RISK_IDENTIFY_STEPS = %i[
  add_a_number_of_hazards_and_subjects_of_harm
].freeze
NORMAL_RISK_CREATE_STEPS = %i[
  choose_hazard_type add_a_harm_scenario_and_probability_of_harm determine_severity_of_harm determine_severity_of_harm_casualties add_uncertainty_and_sensitivity_analysis confirm_overall_product_risk
].freeze
NORMAL_RISK_EVALUATE_STEPS = %i[
  complete_product_risk_evaluation review_and_submit_results_of_the_assessment
].freeze
SERIOUS_RISK_DEFINE_STEPS = %i[
  add_evaluation_details search_or_add_a_new_product
].freeze
SERIOUS_RISK_EVALUATE_STEPS = %i[
  complete_product_risk_evaluation review_and_submit_results_of_the_evaluation
].freeze

# Steps that require a `harm_scenario_id` param
HARM_SCENARIO_STEPS = (NORMAL_RISK_CREATE_STEPS - %i[confirm_overall_product_risk]).map(&:to_s).freeze

# Steps that should be hidden from the task list
NORMAL_RISK_CREATE_STEPS_HIDDEN = %i[determine_severity_of_harm_casualties].freeze
