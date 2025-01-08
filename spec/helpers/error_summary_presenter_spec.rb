require "rails_helper"

RSpec.describe ErrorSummaryPresenter, :with_test_queue_adapter do
  describe "testing GOVUK forms with date fields" do
    context "when the form submitted is an Correspondence Email form" do
      let(:email_correspondence_form) { EmailCorrespondenceForm.new(correspondence_date: nil) }
      let(:email_correspondence_form_with_date) { EmailCorrespondenceForm.new(correspondence_date: Date.new(2023, 2, 11), "correspondence_date(1i)" => 2020, "correspondence_date(2i)" => 1, "correspondence_date(3i)" => 20) }
      let(:email_correspondence_form_complete) { EmailCorrespondenceForm.new(correspondence_date: Date.new(2023, 2, 11), "correspondence_date(1i)" => 2020, "correspondence_date(2i)" => 1, "correspondence_date(3i)" => 20, email_file: Rack::Test::UploadedFile.new("spec/fixtures/files/email.txt")) }

      before do
        email_correspondence_form.invalid?
        email_correspondence_form_with_date.invalid?
        email_correspondence_form_complete.invalid?
      end

      context "when no parameters supplied" do
        it "returns the expected errors" do
          presenter = described_class.new(email_correspondence_form.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:correspondence_date, "Enter the date sent"], [:correspondence_date, "Enter the date sent"], [:base, "Please provide either an email file or a subject and body"]]
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

    context "when the form submitted is an Correspondence Phone Call form" do
      let(:phone_call_correspondence_form) { PhoneCallCorrespondenceForm.new(correspondence_date: nil) }
      let(:phone_call_correspondence_form_with_date) { PhoneCallCorrespondenceForm.new(correspondence_date: Date.new(2023, 2, 11), "correspondence_date(1i)" => 2020, "correspondence_date(2i)" => 1, "correspondence_date(3i)" => 20) }
      let(:phone_call_correspondence_form_complete) { PhoneCallCorrespondenceForm.new(correspondence_date: Date.new(2023, 2, 11), "correspondence_date(1i)" => 2020, "correspondence_date(2i)" => 1, "correspondence_date(3i)" => 20, transcript: Rack::Test::UploadedFile.new("spec/fixtures/files/new_phone_call_transcript.txt")) }

      before do
        phone_call_correspondence_form.invalid?
        phone_call_correspondence_form_with_date.invalid?
        phone_call_correspondence_form_complete.invalid?
      end

      context "when no parameters supplied" do
        it "returns the expected errors" do
          presenter = described_class.new(phone_call_correspondence_form.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:correspondence_date, "Enter the date of call"], [:correspondence_date, "Enter the date of call"], [:overview, "Please provide either a transcript or complete the summary and notes fields"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when :correspondence_date parameter supplied" do
        it "does not return :correspondence_date error" do
          presenter = described_class.new(phone_call_correspondence_form_with_date.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:overview, "Please provide either a transcript or complete the summary and notes fields"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end

      context "when necessary parameters supplied" do
        it "does not return any errors" do
          presenter = described_class.new(phone_call_correspondence_form_complete.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = []
          expect(formatted_errors).to eq(expected_errors)
        end
      end
    end

    context "when the form submitted is an AccidentOrIncident form" do
      let(:accident_or_incident_form) { AccidentOrIncidentForm.new(type: "accident", date: { year: "", month: "", day: "" }) }
      let(:accident_or_incident_form_with_date) { AccidentOrIncidentForm.new(type: "accident", is_date_known: "yes", date: Date.new(2022, 2, 11), "date(1i)" => 2022, "date(2i)" => 2, "date(3i)" => 11) }
      let(:accident_or_incident_form_with_usage) { AccidentOrIncidentForm.new(type: "accident", usage: "during_normal_use") }
      let(:accident_or_incident_form_with_severity) { AccidentOrIncidentForm.new(type: "accident", severity: "serious") }
      let(:accident_or_incident_form_complete) { AccidentOrIncidentForm.new(type: "accident", investigation_product_id: create(:investigation_product).id, is_date_known: "yes", date: Date.new(2022, 2, 11), "date(1i)" => 2022, "date(2i)" => 2, "date(3i)" => 11, usage: "during_normal_use", severity: "serious") }

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
  end

  describe "testing GOVUK forms with multiple errors attached to one attribute" do
    context "when the form submitted is a Product duplicate check form" do
      let(:product_duplicate_check_form) { ProductDuplicateCheckForm.new(has_barcode: true) }

      before do
        product_duplicate_check_form.invalid?
      end

      context "when has_barcode: yes parameter supplied but no barcode is written" do
        it "returns both barcode errors" do
          presenter = described_class.new(product_duplicate_check_form.errors.to_hash(full_messages: true))
          formatted_errors = presenter.formatted_error_messages
          expected_errors = [[:barcode, "The barcode must be between 5 and 15 digits"], [:barcode, "Barcode cannot be blank"]]
          expect(formatted_errors).to eq(expected_errors)
        end
      end
    end
  end
end
