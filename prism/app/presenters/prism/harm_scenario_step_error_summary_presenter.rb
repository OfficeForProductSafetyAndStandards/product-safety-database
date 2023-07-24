module Prism
  class HarmScenarioStepErrorSummaryPresenter
    def initialize(error_messages)
      @error_messages = error_messages
    end

    def formatted_error_messages
      # Even with indexed errors for nested attributes, the attribute name
      # does not take into account the `attributes` suffix added automatically
      # to the name of all form fields, so we add it here to ensure error
      # messages are correctly linked to their associated field.
      @error_messages.map do |attribute, messages|
        [
          attribute.to_s.sub("harm_scenario_steps[", "harm_scenario_steps_attributes[").sub("harm_scenario_step_evidence", "harm_scenario_step_evidence_attributes").to_sym,
          messages.first,
        ]
      end
    end
  end
end
