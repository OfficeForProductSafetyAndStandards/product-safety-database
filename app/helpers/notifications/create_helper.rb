module Notifications
  module CreateHelper
    def sections_complete
      tasks_status = @notification.tasks_status
      Investigation::Notification::TASK_LIST_SECTIONS.map { |_section, tasks|
        complete = tasks.excluding(*Investigation::Notification::TASK_LIST_TASKS_HIDDEN.map(&:keys).flatten).map { |task|
          tasks_status[task.to_s] == "completed" ? 1 : 0
        }.exclude?(0)
        complete ? 1 : 0
      }.inject(&:+)
    end

    def task_status(task)
      optional_tasks = Investigation::Notification::TASK_LIST_SECTIONS.slice(*Investigation::Notification::TASK_LIST_SECTIONS_OPTIONAL).values.flatten
      previous_task = TaskListService.previous_task(task:, all_tasks: wizard_steps, optional_tasks:, hidden_tasks: Investigation::Notification::TASK_LIST_TASKS_HIDDEN)

      if %w[in_progress completed].include?(@notification.tasks_status[task.to_s])
        @notification.tasks_status[task.to_s]
      elsif previous_task.nil? || @notification.tasks_status[previous_task.to_s] == "completed"
        "not_started"
      else
        "cannot_start_yet"
      end
    end

    def task_status_tag(status)
      case status
      when "cannot_start_yet"
        "Cannot start yet"
      when "not_started"
        govuk_tag(text: "Not yet started")
      when "in_progress"
        govuk_tag(text: "In progress", colour: "light-blue")
      when "completed"
        "Completed"
      end
    end

    def sort_by_options
      [
        OpenStruct.new(id: "newly_added", name: "Newly added"),
        OpenStruct.new(id: "name_a_z", name: "Name A-Z"),
        OpenStruct.new(id: "name_z_a", name: "Name Z-A")
      ]
    end

    def reported_reason_options
      [
        OpenStruct.new(id: "unsafe_or_non_compliant", name: "A product is unsafe or non-compliant", description: "Examples of non-compliance in products include missing or incomplete markings, errors in product labeling, or inadequate documentation."),
        OpenStruct.new(id: "safe_and_compliant", name: "A product is safe and compliant", description: "This helps other market surveillance authorities avoid testing the same product again.")
      ]
    end

    def hazards_options
      [OpenStruct.new(id: "", name: "")] +
        Rails.application.config.hazard_constants["hazard_type"].map do |hazard_type|
          OpenStruct.new(id: hazard_type, name: hazard_type)
        end
    end

    def countries_options
      [OpenStruct.new(id: "", name: "")] +
        Country.overseas_countries.map do |country|
          OpenStruct.new(id: country[1], name: country[0])
        end
    end

    def number_of_affected_units(investigation_products)
      investigation_products.map { |investigation_product|
        units = case investigation_product.affected_units_status
                when "exact"
                  investigation_product.number_of_affected_units
                when "approx"
                  "Approximately #{investigation_product.number_of_affected_units}"
                when "unknown"
                  "Unknown"
                when "not_relevant"
                  "Not relevant"
                else
                  "Not provided"
                end
        "#{investigation_product.product.decorate.name_with_brand}: #{units}"
      }.join("<br>")
    end

    def investigation_products_options
      @notification.investigation_products.decorate.map do |investigation_product|
        OpenStruct.new(id: investigation_product.id, name: investigation_product.product.name_with_brand)
      end
    end

    def legislation_options
      [OpenStruct.new(id: "", name: "")] +
        Rails.application.config.legislation_constants["legislation"].map do |legislation|
          OpenStruct.new(id: legislation, name: legislation)
        end
    end

    def team_options
      [OpenStruct.new(id: "", name: "")] +
        Team.all.order(:name).map do |team|
          OpenStruct.new(id: team.id, name: team.name)
        end
    end

    def specific_product_safety_issues
      unsafe = "<p class=\"govuk-body\">Product harm: #{@notification.hazard_type}</p><p class=\"govuk-body-s\">#{@notification.hazard_description}</p>" if @notification.unsafe? || @notification.unsafe_and_non_compliant?
      non_compliant = "<p class=\"govuk-body\">Product incomplete markings, labeling or other issues</p><p class=\"govuk-body-s\">#{@notification.non_compliant_reason}</p>" if @notification.non_compliant? || @notification.unsafe_and_non_compliant?
      [unsafe, non_compliant].join
    end

    def formatted_business_address(location)
      [location.address_line_1, location.address_line_2, location.city, location.county, location.postal_code, country_from_code(location.country)].map(&:presence).compact.join("<br>")
    end

    def formatted_business_contact(contact)
      [contact.name, contact.job_title, contact.email, contact.phone_number].map(&:presence).compact.join("<br>")
    end

    def formatted_test_results(test_results)
      test_results.map { |test_result| link_to "#{test_result.document.blob.filename} (opens in new tab)", test_result.document.blob, class: "govuk-link", target: "_blank", rel: "noreferrer noopener" if test_result.document.blob.present? }.join("<br>")
    end

    def formatted_risk_assessments(prism_risk_assessments, risk_assessments, notification_id, risk_assessment_list)
      if notification_id.nil?  && risk_assessment_list.nil?
        (prism_risk_assessments.decorate + risk_assessments.decorate).map(&:supporting_information_full_title).compact.join("<br>")
      else
        hyperlinks = ""
        risk_assessment_list.each_with_index do |risk, index|
          hyperlinks += "<div><a class='govuk-link' href='/cases/#{notification_id}/risk-assessments/#{risk.id}'>#{(prism_risk_assessments.decorate + risk_assessments.decorate).map(&:supporting_information_full_title).compact[index]}<br></a></div>"
        end
        hyperlinks
      end
    end

    def formatted_uploads(uploads)
      uploads.map { |upload| link_to "#{upload.blob.filename} (opens in new tab)", upload.blob, class: "govuk-link", target: "_blank", rel: "noreferrer noopener" if upload.blob.present? }.join("<br>")
    end

    def risk_level_tag
      case @notification.risk_level
      when "low"
        govuk_tag(text: "Low risk", colour: "green")
      when "medium"
        govuk_tag(text: "Medium risk", colour: "yellow")
      when "high"
        govuk_tag(text: "High risk", colour: "orange")
      when "serious"
        govuk_tag(text: "Serious risk", colour: "red")
      when "not_conclusive"
        govuk_tag(text: "Not conclusive", colour: "grey")
      else
        govuk_tag(text: "Unknown risk", colour: "grey")
      end
    end

    def corrective_action_not_taken_reasons
      @notification.corrective_action_taken_other? ? @notification.corrective_action_not_taken_reason : I18n.t("corrective_action.not_taken_reason.#{@notification.corrective_action_taken}")
    end
  end
end
