require "rails_helper"

RSpec.describe ErrorSummaryUpperCasePresenter, :with_test_queue_adapter do
  describe "testing GOVUK forms with date fields" do
    context "when the form submitted is an AccidentOrIncident form" do
      let(:accident_or_incident_form) { AccidentOrIncidentForm.new(type: "accident", date: { year: "", month: "", day: "" }) }
      let(:accident_or_incident_form_with_date) { AccidentOrIncidentForm.new(type: "accident", is_date_known: "yes", date: Date.new(2022, 2, 11)) }
      let(:accident_or_incident_form_with_usage) { AccidentOrIncidentForm.new(type: "accident", usage: "during_normal_use") }
      let(:accident_or_incident_form_with_severity) { AccidentOrIncidentForm.new(type: "accident", severity: "serious") }
      let(:accident_or_incident_form_complete) { AccidentOrIncidentForm.new(type: "accident", investigation_product_id: create(:investigation_product).id, is_date_known: "yes", date: Date.new(2022, 2, 11), usage: "during_normal_use", severity: "serious") }

      before do
        accident_or_incident_form.invalid?
        accident_or_incident_form_with_date.invalid?
        accident_or_incident_form_with_usage.invalid?
        accident_or_incident_form_with_severity.invalid?
        accident_or_incident_form_complete.invalid?
      end

      context "when no parameters supplied" do
        it "returns the expected errors" do
          presenter = described_class.new(accident_or_incident_form.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:is_date_known, "Select yes if you know when the accident happened"], [:investigation_product_id, "Select the product involved in the accident"], [:usage, "Select how the product was being used"], [:severity, "Select the severity of the accident"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when date is known parameter and date parameter supplied" do
        it "does not have date error when parameter is filled" do
          presenter = described_class.new(accident_or_incident_form_with_date.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:investigation_product_id, "Select the product involved in the accident"], [:usage, "Select how the product was being used"], [:severity, "Select the severity of the accident"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when :usage parameter is supplied" do
        it "does not have :usage error" do
          presenter = described_class.new(accident_or_incident_form_with_usage.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:is_date_known, "Select yes if you know when the accident happened"], [:investigation_product_id, "Select the product involved in the accident"], [:severity, "Select the severity of the accident"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when :severity parameter is supplied" do
        it "does not have :severity error" do
          presenter = described_class.new(accident_or_incident_form_with_severity.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:is_date_known, "Select yes if you know when the accident happened"], [:investigation_product_id, "Select the product involved in the accident"], [:usage, "Select how the product was being used"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when all parameters supplied" do
        it "does not have errors" do
          presenter = described_class.new(accident_or_incident_form_complete.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = []
          expect(formatted_errors).to eq(expected_errors)
        end
      end
    end

    context "when the form submitted is an RiskAssessment form" do
      let(:risk_assessment_form) { RiskAssessmentForm.new }
      let(:risk_assessment_form_with_assessed_on) { RiskAssessmentForm.new(assessed_on: Date.new(2023, 2, 11)) }
      let(:risk_assessment_form_with_risk_level) { RiskAssessmentForm.new(risk_level: "high") }
      let(:my_team) { Team.find("0f63100e-d161-481d-a969-c205f3796df2") }
      let(:risk_assessment_form_with_assessed_by) { RiskAssessmentForm.new(assessed_by: :my_team) }
      let(:risk_assessment_form_with_product_id) { RiskAssessmentForm.new(investigation_product_ids: [create(:investigation_product).id]) }
      let(:risk_assessment_form_with_file) { RiskAssessmentForm.new(risk_assessment_file: Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt")) }
      let(:risk_assessment_form_complete) { RiskAssessmentForm.new(assessed_on: Date.new(2023, 2, 11), risk_level: "high", assessed_by: :my_team, investigation_product_ids: [create(:investigation_product).id], risk_assessment_file: Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt")) }

      before do
        risk_assessment_form.invalid?
        risk_assessment_form_with_assessed_on.invalid?
        risk_assessment_form_with_risk_level.invalid?
        risk_assessment_form_with_assessed_by.invalid?
        risk_assessment_form_with_product_id.invalid?
        risk_assessment_form_with_file.invalid?
        risk_assessment_form_complete.invalid?
      end

      context "when no parameters supplied" do
        it "returns the expected errors" do
          presenter = described_class.new(risk_assessment_form.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:assessed_on, "Enter the date of the assessment"], [:risk_level, "Select the risk level"], [:assessed_by, "Select who completed the assessment"], [:investigation_product_ids, "You must choose at least one product"], [:risk_assessment_file, "You must upload the risk assessment"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when assessed_on on parameter supplied" do
        it "does not have :assessed_on error" do
          presenter = described_class.new(risk_assessment_form_with_assessed_on.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:risk_level, "Select the risk level"], [:assessed_by, "Select who completed the assessment"], [:investigation_product_ids, "You must choose at least one product"], [:risk_assessment_file, "You must upload the risk assessment"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when risk_level on parameter supplied" do
        it "does not have :risk_level error" do
          presenter = described_class.new(risk_assessment_form_with_risk_level.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:assessed_on, "Enter the date of the assessment"], [:assessed_by, "Select who completed the assessment"], [:investigation_product_ids, "You must choose at least one product"], [:risk_assessment_file, "You must upload the risk assessment"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when :assessed_by parameter supplied" do
        it "does not have :assessed_by error" do
          presenter = described_class.new(risk_assessment_form_with_assessed_by.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:assessed_on, "Enter the date of the assessment"], [:risk_level, "Select the risk level"], [:investigation_product_ids, "You must choose at least one product"], [:risk_assessment_file, "You must upload the risk assessment"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when :investigation_products_ids parameter supplied" do
        it "does not have :investigation_products_ids error" do
          presenter = described_class.new(risk_assessment_form_with_product_id.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:assessed_on, "Enter the date of the assessment"], [:risk_level, "Select the risk level"], [:assessed_by, "Select who completed the assessment"], [:risk_assessment_file, "You must upload the risk assessment"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when :risk_assessment_file parameter supplied" do
        it "does not have :risk_assessment_file error" do
          presenter = described_class.new(risk_assessment_form_with_file.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:assessed_on, "Enter the date of the assessment"], [:risk_level, "Select the risk level"], [:assessed_by, "Select who completed the assessment"], [:investigation_product_ids, "You must choose at least one product"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when all parameters supplied" do
        it "does not have errors" do
          presenter = described_class.new(risk_assessment_form_complete.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = []
          expect(formatted_errors).to eq(expected_errors)
        end
      end
    end

    context "when the form submitted is an Correspondence Email form" do
      let(:email_correspondence_form) { EmailCorrespondenceForm.new }
      let(:email_correspondence_form_with_date) { EmailCorrespondenceForm.new(correspondence_date: Date.new(2023, 2, 11), "correspondence_date(1i)" => 2020, "correspondence_date(2i)" => 1, "correspondence_date(3i)" => 20) }
      let(:email_correspondence_form_complete) { EmailCorrespondenceForm.new(correspondence_date: Date.new(2023, 2, 11), "correspondence_date(1i)" => 2020, "correspondence_date(2i)" => 1, "correspondence_date(3i)" => 20, email_file: Rack::Test::UploadedFile.new("spec/fixtures/files/email.txt")) }

      before do
        email_correspondence_form.invalid?
        email_correspondence_form_with_date.invalid?
      end

      context "when no parameters supplied" do
        it "returns the expected errors" do
          presenter = described_class.new(email_correspondence_form.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:correspondence_date, "Enter the date sentEnter the date sent"], [:base, "Please provide either an email file or a subject and body"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when :correspondence_date parameter supplied" do
        it "does not return :correspondence_date error" do
          presenter = described_class.new(email_correspondence_form_with_date.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:base, "Please provide either an email file or a subject and body"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when all parameters supplied" do
        it "does not return any errors" do
          presenter = described_class.new(email_correspondence_form_complete.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = []
          expect(formatted_errors).to eq(expected_errors)
        end
      end
    end
  end
end
