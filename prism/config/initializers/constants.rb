# Define wizard steps for normal and serious risk pathways split by section
NORMAL_RISK_DEFINE_STEPS = %i[
  add_assessment_details add_details_about_products_in_use_and_safety
].freeze
NORMAL_RISK_IDENTIFY_STEPS = %i[
  add_a_number_of_hazards
].freeze
NORMAL_RISK_CREATE_STEPS = %i[
  choose_hazard_type identify_who_might_be_harmed add_steps_to_harm determine_severity_of_harm estimate_probability_of_harm check_your_harm_scenario
].freeze
NORMAL_RISK_OUTCOME_STEPS = %i[
  confirm_overall_product_risk add_level_of_uncertainty_and_sensitivity_analysis
].freeze
NORMAL_RISK_EVALUATE_STEPS = %i[
  consider_the_nature_of_the_risk consider_perception_and_tolerability_of_the_risk risk_evaluation_outcome review_and_submit_results_of_the_assessment
].freeze
SERIOUS_RISK_DEFINE_STEPS = %i[
  add_evaluation_details
].freeze
SERIOUS_RISK_OUTCOME_STEPS = %i[
  add_level_of_uncertainty_and_sensitivity_analysis
].freeze
SERIOUS_RISK_EVALUATE_STEPS = %i[
  consider_the_nature_of_the_risk consider_perception_and_tolerability_of_the_risk risk_evaluation_outcome review_and_submit_results_of_the_evaluation
].freeze
