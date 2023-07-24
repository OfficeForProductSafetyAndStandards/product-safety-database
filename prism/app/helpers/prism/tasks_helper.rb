module Prism
  module TasksHelper
    def normal_risk_sections
      {
        "define" => NORMAL_RISK_DEFINE_STEPS.map(&:to_s),
        "identify" => NORMAL_RISK_IDENTIFY_STEPS.map(&:to_s),
        "create" => NORMAL_RISK_CREATE_STEPS.map(&:to_s) - NORMAL_RISK_CREATE_STEPS_HIDDEN.map(&:to_s),
        "evaluate" => NORMAL_RISK_EVALUATE_STEPS.map(&:to_s),
      }
    end

    def serious_risk_sections
      {
        "define" => SERIOUS_RISK_DEFINE_STEPS.map(&:to_s),
        "evaluate" => SERIOUS_RISK_EVALUATE_STEPS.map(&:to_s),
      }
    end

    def sections_complete
      sections = @prism_risk_assessment.serious_risk? ? serious_risk_sections : normal_risk_sections
      statuses = @prism_risk_assessment.tasks_status
      sections.map { |_section, tasks| statuses.slice(*tasks).values.all?("completed") }.count(true)
    end

    def tasks_status
      original_tasks_status = @prism_risk_assessment.tasks_status
      @tasks_status ||= original_tasks_status.each_with_object({}).with_index do |((task, status), statuses), index|
        statuses[task] = if status == "not_started" && index.positive? && original_tasks_status[original_tasks_status.keys[index - 1]] == "not_started"
                           "cannot_start_yet"
                         else
                           status
                         end
      end
    end

    def task_status_tag(status)
      case status
      when "cannot_start_yet"
        govuk_tag(text: "Cannot start yet", colour: "grey")
      when "not_started"
        govuk_tag(text: "Not started", colour: "grey")
      when "in_progress"
        govuk_tag(text: "In progress")
      when "completed"
        govuk_tag(text: "Completed")
      end
    end

    def number_of_hazards_radios
      [
        OpenStruct.new(id: "one", name: "1"),
        OpenStruct.new(id: "two", name: "2"),
        OpenStruct.new(id: "three", name: "3"),
        OpenStruct.new(id: "four", name: "4"),
        OpenStruct.new(id: "five", name: "5"),
        OpenStruct.new(id: "more_than_five", name: "More than 5"),
      ]
    end

    def hazard_type
      return unless @harm_scenario

      @harm_scenario.other? ? @harm_scenario.other_hazard_type : I18n.t("prism.harm_scenarios.hazard_types.#{@harm_scenario.hazard_type}")
    end

    def affected_users
      return unless @prism_risk_assessment.product_hazard

      I18n.t("prism.product_hazard.product_aimed_at.#{@prism_risk_assessment.product_hazard.product_aimed_at}")
    end

    def severity_radios
      level_1_examples = <<~EXAMPLES.strip
        <ul class="govuk-list govuk-list--bullet">
          <li>minor cuts, bruising, pinching, sprains and strains</li>
          <li>piercing</li>
          <li>1<sup>st</sup> degree burns or 2<sup>nd</sup> degree burns &lt;6% of body surface</li>
          <li>poisoning causing diarrhoea or vomiting</li>
          <li>local slight irritation</li>
          <li>mild or local allergic reactions</li>
        </ul>
      EXAMPLES
      level_1_hint = capture do
        concat "Injury or ill health that after basic treatment (first aid, normally not by a doctor) does not substantially hamper functioning or cause excessive pain; usually the consequences are completely reversible."
        concat govuk_details(summary_text: "Examples of Level 1 harm", classes: %w[govuk-!-padding-top-4], text: level_1_examples.html_safe)
      end
      level_2_examples = <<~EXAMPLES.strip
        <ul class="govuk-list govuk-list--bullet">
          <li>cuts &gt;10 cm on body and &gt;5 cm on face, requiring stitches</li>
          <li>major bruising (&gt; 50 cm<sup>2</sup> on body and &gt;25 cm<sup>2</sup> on face)</li>
          <li>concussion involving a short period of unconsciousness</li>
          <li>dislocations or fractures of finger, toe, hand, foot or jaw</li>
          <li>fractures of wrist, arm, rib, nose or jaw</li>
          <li>piercing deeper than the skin</li>
          <li>2<sup>nd</sup> degree burns 6-15% of body surface</li>
          <li>electric shock causing temporary cramp or muscle paralysis</li>
          <li>temporary loss of sight or hearing</li>
          <li>poisoning causing reversible damage to internal organs</li>
          <li>allergic reactions and widespread allergic contact dermatitis</li>
          <li>reversible damage from microbiological infection</li>
        </ul>
      EXAMPLES
      level_2_hint = capture do
        concat "Injury or ill health for which a visit to A&E may be necessary, but in general, hospitalisation is not required. Functioning may be affected for a limited period, not more than about 6 months, and recovery is more or less complete."
        concat govuk_details(summary_text: "Examples of Level 2 harm", classes: %w[govuk-!-padding-top-4], text: level_2_examples.html_safe)
      end
      level_3_examples = <<~EXAMPLES.strip
        <ul class="govuk-list govuk-list--bullet">
          <li>cuts/laceration or bruising to trachea or internal organs</li>
          <li>concussion causing prolonged unconsciousness</li>
          <li>sprains and strains causing muscle, ligament or tendon rupture/tear</li>
          <li>dislocation of ankle, wrist, shoulder, hip, knee or spine</li>
          <li>fracture of ankle, leg, hip, skull, spine (minor compression fracture), jaw (severe), more than 1 rib</li>
          <li>crushing of extremities, arm, leg, trachea or pelvis</li>
          <li>amputation of finger/s, toe/s, hand, foot, arm, leg or eye</li>
          <li>piercing of eye, internal organs or chest wall</li>
          <li>ingestion causing internal organ injury</li>
          <li>internal airway obstruction or suffocation/strangulation without permanent consequences</li>
          <li>2<sup>nd</sup> degree burns 16-35% of body surface and 3<sup>rd</sup> degree burns up to 35% of body surface</li>
          <li>epileptic seizure</li>
          <li>permanent loss of sight (one eye) or hearing (one ear)</li>
          <li>poisoning causing irreversible damage to internal organs</li>
          <li>strong sensitisation provoking allergies to multiple substances</li>
          <li>irreversible effects from microbiological infection</li>
        </ul>
      EXAMPLES
      level_3_hint = capture do
        concat "Injury or ill health that normally requires hospitalisation and will affect functioning for more than 6 months or lead to a permanent loss of function."
        concat govuk_details(summary_text: "Examples of Level 3 harm", classes: %w[govuk-!-padding-top-4], text: level_3_examples.html_safe)
      end
      level_4_examples = <<~EXAMPLES.strip
        <ul class="govuk-list govuk-list--bullet">
          <li>cuts/laceration of spinal cord, brain, oesophagus, deep laceration of internal organs</li>
          <li>bruising of brain stem or spinal cord causing paralysis</li>
          <li>concussion resulting in coma</li>
          <li>dislocation or fracture of spinal column</li>
          <li>fracture of neck</li>
          <li>crushing of spinal cord, chest (severe) or brain stem</li>
          <li>amputation of both arms or both legs</li>
          <li>piercing of aorta, heart, bronchial tube or causing deep injuries in organs</li>
          <li>ingestion causing permanent damage to internal organ</li>
          <li>internal airway obstruction with permanent consequences</li>
          <li>2<sup>nd</sup> or 3<sup>rd</sup> degree burns &gt;35% of body surface</li>
          <li>electrocution</li>
          <li>permanent loss of sight (both eyes) or hearing (both ears)</li>
          <li>poisoning causing irreversible damage to nerve system</li>
          <li>anaphylactic reactions</li>
          <li>prolonged hospitalisation from microbiological infection</li>
        </ul>
      EXAMPLES
      level_4_hint = capture do
        concat "Injury or ill health Injury or ill health that is, or could be, fatal, including brain death; consequences that affect reproduction or unborn children; severe loss of limbs and/or function, leading to more than approximately 10% of disability."
        concat govuk_details(summary_text: "Examples of Level 4 harm", classes: %w[govuk-!-padding-top-4], text: level_4_examples.html_safe)
      end
      [
        OpenStruct.new(id: "level_1", name: "Level 1", description: level_1_hint),
        OpenStruct.new(id: "level_2", name: "Level 2", description: level_2_hint),
        OpenStruct.new(id: "level_3", name: "Level 3", description: level_3_hint),
        OpenStruct.new(id: "level_4", name: "Level 4", description: level_4_hint),
      ]
    end

    def severity_of_harm
      return unless @harm_scenario

      I18n.t("prism.harm_scenarios.severity.#{@harm_scenario.severity}")
    end

    def probability_of_harm(type:, probability:)
      type == "frequency" ? "1 in #{probability}" : probability
    end

    def overall_probability_of_harm
      return unless @harm_scenario

      Prism::ProbabilityService.overall_probability_of_harm(harm_scenario: @harm_scenario)
    end

    def overall_risk_level_tag
      return unless @harm_scenario

      risk_level = Prism::RiskMatrixService.risk_level(probability_frequency: overall_probability_of_harm.probability, severity_level: @harm_scenario.severity.to_sym)

      case risk_level
      when "low"
        govuk_tag(text: "Low risk", colour: "green")
      when "medium"
        govuk_tag(text: "Medium risk", colour: "yellow")
      when "high"
        govuk_tag(text: "High risk", colour: "orange")
      when "serious"
        govuk_tag(text: "Serious risk", colour: "red")
      end
    end

    def harm_scenario_step_summary(harm_scenario_step)
      file = harm_scenario_step.harm_scenario_step_evidence&.evidence_file
      [
        harm_scenario_step.description,
        "Probability of harm: #{probability_of_harm(**harm_scenario_step.probability_of_harm)}",
        "Evidence: #{t("prism.harm_scenario_steps.probability_evidence.#{harm_scenario_step.probability_evidence}")}",
        ("<a href=\"#{main_app.rails_storage_proxy_path(file)}\" class=\"govuk-link\" rel=\"noreferrer noopener\" target=\"_blank\">#{file.blob.filename}</a>" if file && file.metadata["safe"] == true),
      ].join("<br>")
    end

    def file_icon_url(content_type)
      case content_type
      when "application/pdf"
        image_path("prism/icons/pdf-file.png")
      when "image/jpeg"
        image_path("prism/icons/jpg-file.png")
      when "image/gif"
        image_path("prism/icons/gif-file.png")
      when "image/png"
        image_path("prism/icons/png-file.png")
      when "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        image_path("prism/icons/doc-file.png")
      when "application/vnd.ms-powerpoint", "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        image_path("prism/icons/ppt-file.png")
      when "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        image_path("prism/icons/xls-file.png")
      else
        image_path("prism/icons/blank-file.png")
      end
    end
  end
end
