require "rails_helper"

RSpec.describe ApplicationFormBuilder, type: :helper do
  let(:object) { instance_double(User) } # Replace 'User' with your actual model class name
  let(:template) { instance_spy(ActionView::Base) }
  let(:builder) { described_class.new(:object, object, template, {}) }

  let(:errors) { instance_double(ActiveModel::Errors) }

  before do
    allow(object).to receive(:errors).and_return(errors)
  end

  describe "#govuk_date_input" do
    let(:attribute) { :date_of_birth }
    let(:legend) { "Date of birth" }
    let(:hint) { "For example, 31 3 1980" }
    let(:date) { Date.new(1980, 3, 31) }

    before do
      allow(object).to receive(:public_send).with(attribute).and_return(date)
    end

    context "when there are no errors" do
      before { allow(errors).to receive(:include?).with(attribute).and_return(false) }

      it "renders the govukDateInput with correct parameters" do
        builder.govuk_date_input(attribute, legend:, hint:)
        expect_correct_govuk_date_input_rendering
      end
    end

    context "when there are errors" do
      before do
        allow(errors).to receive(:include?).with(attribute).and_return(true)
        allow(errors).to receive(:full_messages_for).with(attribute).and_return(["Date of birth is invalid"])
      end

      it "renders the govukDateInput with error message" do
        builder.govuk_date_input(attribute, legend:, hint:)
        expect_govuk_date_input_rendering_with_errors
      end
    end
  end

  describe "#govuk_text_area" do
    let(:attribute) { :description }
    let(:label) { "Description" }
    let(:hint) { "Provide a brief description" }

    before do
      allow(object).to receive(:public_send).with(attribute).and_return("Sample description")
    end

    context "when there are no errors" do
      before { allow(errors).to receive(:include?).with(attribute).and_return(false) }

      it "renders the govukTextarea with correct parameters" do
        builder.govuk_text_area(attribute, label:, hint:)
        expect_correct_govuk_text_area_rendering
      end
    end

    context "when there are errors" do
      before do
        allow(errors).to receive(:include?).with(attribute).and_return(true)
        allow(errors).to receive(:full_messages_for).with(attribute).and_return(["Description is too short"])
      end

      it "renders the govukTextarea with error message" do
        builder.govuk_text_area(attribute, label:, hint:)
        expect_govuk_text_area_rendering_with_errors
      end
    end
  end

  describe "#govuk_input" do
    let(:attribute) { :name }
    let(:label) { "Name" }
    let(:value) { "John Doe" }

    before do
      allow(object).to receive(:public_send).with(attribute).and_return(value)
    end

    context "when there are no errors" do
      before { allow(errors).to receive(:include?).with(attribute).and_return(false) }

      it "renders the govukInput with correct parameters" do
        builder.govuk_input(attribute, label:)
        expect_correct_govuk_input_rendering
      end
    end

    context "when there are errors" do
      before do
        allow(errors).to receive(:include?).with(attribute).and_return(true)
        allow(errors).to receive(:full_messages_for).with(attribute).and_return(["Name can't be blank"])
      end

      it "renders the govukInput with error message" do
        builder.govuk_input(attribute, label:)
        expect_govuk_input_rendering_with_errors
      end
    end
  end

  describe "#govuk_select" do
    let(:attribute) { :role }
    let(:label) { "Role" }
    let(:items) { [{ text: "Admin", value: "admin" }, { text: "User", value: "user" }] }

    before do
      allow(object).to receive(:public_send).with(attribute).and_return("admin")
    end

    context "when there are no errors" do
      before { allow(errors).to receive(:include?).with(attribute).and_return(false) }

      it "renders the govukSelect with correct parameters" do
        builder.govuk_select(attribute, label:, items:)
        expect_correct_govuk_select_rendering
      end
    end

    context "when there are errors" do
      before do
        allow(errors).to receive(:include?).with(attribute).and_return(true)
        allow(errors).to receive(:full_messages_for).with(attribute).and_return(["Role is invalid"])
      end

      it "renders the govukSelect with error message" do
        builder.govuk_select(attribute, label:, items:)
        expect_govuk_select_rendering_with_errors
      end
    end
  end

  describe "#govuk_checkboxes" do
    let(:attribute) { :preferences }
    let(:legend) { "Preferences" }
    let(:items) { [{ text: "Option 1", value: "option_1" }, { text: "Option 2", value: "option_2" }] }

    before do
      allow(object).to receive(:public_send).with(attribute).and_return(%w[option_1])
    end

    context "when there are no errors" do
      before { allow(errors).to receive(:include?).with(attribute).and_return(false) }

      it "renders the govukCheckboxes with correct parameters" do
        builder.govuk_checkboxes(attribute, legend:, items:)
        expect_correct_govuk_checkboxes_rendering
      end
    end

    context "when there are errors" do
      before do
        allow(errors).to receive(:include?).with(attribute).and_return(true)
        allow(errors).to receive(:full_messages_for).with(attribute).and_return(["Preferences is invalid"])
      end

      it "renders the govukCheckboxes with error message" do
        builder.govuk_checkboxes(attribute, legend:, items:)
        expect_govuk_checkboxes_rendering_with_errors
      end
    end
  end

  describe "#govuk_radios" do
    let(:attribute) { :newsletter }
    let(:legend) { "Newsletter" }
    let(:items) { [{ text: "Yes", value: "yes" }, { text: "No", value: "no" }] }

    before do
      allow(object).to receive(:public_send).with(attribute).and_return("yes")
    end

    context "when there are no errors" do
      before { allow(errors).to receive(:include?).with(attribute).and_return(false) }

      it "renders the govukRadios with correct parameters" do
        builder.govuk_radios(attribute, legend:, items:)
        expect_correct_govuk_radios_rendering
      end
    end

    context "when there are errors" do
      before do
        allow(errors).to receive(:include?).with(attribute).and_return(true)
        allow(errors).to receive(:full_messages_for).with(attribute).and_return(["Newsletter selection is invalid"])
      end

      it "renders the govukRadios with error message" do
        builder.govuk_radios(attribute, legend:, items:)
        expect_govuk_radios_rendering_with_errors
      end
    end
  end

  describe "#govuk_file_upload" do
    let(:attribute) { :document }
    let(:label) { "Upload Document" }
    let(:hint) { "Choose a file to upload" }

    before do
      allow(object).to receive(:errors).and_return(errors)
    end

    context "when there are no errors" do
      before { allow(errors).to receive(:include?).with(attribute).and_return(false) }

      it "renders the govukFileUpload with correct parameters and sets multipart form" do
        builder.govuk_file_upload(attribute, label:, hint:)
        expect_correct_govuk_file_upload_rendering
        expect(builder.multipart).to be(true)
      end
    end

    context "when there are errors" do
      before do
        allow(errors).to receive(:include?).with(attribute).and_return(true)
        allow(errors).to receive(:full_messages_for).with(attribute).and_return(["Document can't be blank"])
      end

      it "renders the govukFileUpload with error message and sets multipart form" do
        builder.govuk_file_upload(attribute, label:, hint:)
        expect_govuk_file_upload_rendering_with_errors
        expect(builder.multipart).to be(true)
      end
    end
  end

private

  def expect_correct_govuk_date_input_rendering
    expected_params = {
      id: "#{attribute}-fieldset",
      errorMessage: nil,
      hint: { text: hint },
      fieldset: {
        legend: {
          classes: "govuk-fieldset__legend--m",
          text: legend
        }
      },
      items: [
        {
          classes: "govuk-input--width-2",
          label: "Day",
          id: attribute,
          name: "object[date_of_birth][day]",
          value: 31
        },
        {
          classes: "govuk-input--width-2",
          label: "Month",
          name: "object[date_of_birth][month]",
          value: 3
        },
        {
          classes: "govuk-input--width-4",
          label: "Year",
          name: "object[date_of_birth][year]",
          value: 1980
        }
      ]
    }

    expect(template).to have_received(:govukDateInput).with(expected_params)
  end

  def expect_govuk_date_input_rendering_with_errors
    expected_params = {
      id: "#{attribute}-fieldset",
      errorMessage: { text: "Date of birth is invalid" },
      hint: { text: hint },
      fieldset: {
        legend: {
          classes: "govuk-fieldset__legend--m",
          text: legend
        }
      },
      items: [
        {
          classes: "govuk-input--width-2 govuk-input--error",
          label: "Day",
          id: attribute,
          name: "object[date_of_birth][day]",
          value: 31
        },
        {
          classes: "govuk-input--width-2 govuk-input--error",
          label: "Month",
          name: "object[date_of_birth][month]",
          value: 3
        },
        {
          classes: "govuk-input--width-4 govuk-input--error",
          label: "Year",
          name: "object[date_of_birth][year]",
          value: 1980
        }
      ]
    }

    expect(template).to have_received(:govukDateInput).with(expected_params)
  end

  def expect_correct_govuk_text_area_rendering
    expected_params = {
      label: { text: label, classes: "govuk-label--m" },
      hint: { text: hint },
      name: "object[description]",
      id: attribute.to_s,
      value: "Sample description",
      errorMessage: nil,
      attributes: {},
      classes: nil,
      rows: 5,
      described_by: nil
    }

    expect(template).to have_received(:govukTextarea).with(expected_params)
  end

  def expect_govuk_text_area_rendering_with_errors
    expected_params = {
      label: { text: label, classes: "govuk-label--m" },
      hint: { text: hint },
      name: "object[description]",
      id: attribute.to_s,
      value: "Sample description",
      errorMessage: { text: "Description is too short" },
      attributes: {},
      classes: nil,
      rows: 5,
      described_by: nil
    }

    expect(template).to have_received(:govukTextarea).with(expected_params)
  end

  def expect_correct_govuk_input_rendering
    expected_params = {
      id: attribute.to_s,
      name: "object[name]",
      value:,
      errorMessage: nil,
      label: { text: label, classes: "" },
      hint: nil
    }

    expect(template).to have_received(:govukInput).with(expected_params)
  end

  def expect_govuk_input_rendering_with_errors
    expected_params = {
      id: attribute.to_s,
      name: "object[name]",
      value:,
      errorMessage: { text: "Name can't be blank" },
      label: { text: label, classes: "" },
      hint: nil
    }

    expect(template).to have_received(:govukInput).with(expected_params)
  end

  def expect_correct_govuk_select_rendering
    expected_params = {
      id: attribute.to_s,
      name: "object[role]",
      label: { text: label, classes: "" },
      hint: nil,
      items: [
        { text: "Admin", value: "admin", selected: true },
        { text: "User", value: "user" }
      ],
      errorMessage: nil,
      include_blank: false,
      attributes: { multiple: false }
    }

    expect(template).to have_received(:govukSelect).with(expected_params)
  end

  def expect_govuk_select_rendering_with_errors
    expected_params = {
      id: attribute.to_s,
      name: "object[role]",
      label: { text: label, classes: "" },
      hint: nil,
      items: [
        { text: "Admin", value: "admin", selected: true },
        { text: "User", value: "user" }
      ],
      errorMessage: { text: "Role is invalid" },
      include_blank: false,
      attributes: { multiple: false }
    }

    expect(template).to have_received(:govukSelect).with(expected_params)
  end

  def expect_correct_govuk_checkboxes_rendering
    expected_params = {
      errorMessage: nil,
      items: [
        { text: "Option 1", value: "option_1", checked: true, name: "object[preferences][]", id: "preferences" },
        { text: "Option 2", value: "option_2", name: "object[preferences][]", id: "preferences-1" }
      ],
      hint: nil,
      fieldset: {
        legend: {
          html: legend,
          classes: "govuk-fieldset__legend--m"
        }
      }
    }

    expect(template).to have_received(:govukCheckboxes).with(expected_params)
  end

  def expect_govuk_checkboxes_rendering_with_errors
    expected_params = {
      errorMessage: { text: "Preferences is invalid" },
      items: [
        { text: "Option 1", value: "option_1", checked: true, name: "object[preferences][]", id: "preferences" },
        { text: "Option 2", value: "option_2", name: "object[preferences][]", id: "preferences-1" }
      ],
      hint: nil,
      fieldset: {
        legend: {
          html: legend,
          classes: "govuk-fieldset__legend--m"
        }
      }
    }

    expect(template).to have_received(:govukCheckboxes).with(expected_params)
  end

  def expect_correct_govuk_radios_rendering
    expected_params = {
      name: "object[newsletter]",
      errorMessage: nil,
      items: [
        { text: "Yes", value: "yes", checked: true, id: "newsletter" },
        { text: "No", value: "no", checked: false, id: "newsletter-1" }
      ],
      fieldset: {
        legend: {
          text: legend,
          classes: "govuk-fieldset__legend--m",
          isPageHeading: false
        }
      }
    }

    expect(template).to have_received(:govukRadios).with(expected_params)
  end

  def expect_govuk_radios_rendering_with_errors
    expected_params = {
      name: "object[newsletter]",
      errorMessage: { text: "Newsletter selection is invalid" },
      items: [
        { text: "Yes", value: "yes", checked: true, id: "newsletter" },
        { text: "No", value: "no", checked: false, id: "newsletter-1" }
      ],
      fieldset: {
        legend: {
          text: legend,
          classes: "govuk-fieldset__legend--m",
          isPageHeading: false
        }
      }
    }

    expect(template).to have_received(:govukRadios).with(expected_params)
  end

  def expect_correct_govuk_file_upload_rendering
    expected_params = {
      id: attribute,
      name: "object[document]",
      errorMessage: nil,
      classes: nil,
      hint: { text: hint },
      label: {
        text: label,
        classes: ""
      },
      attributes: {}
    }

    expect(template).to have_received(:govukFileUpload).with(expected_params)
  end

  def expect_govuk_file_upload_rendering_with_errors
    expected_params = {
      id: attribute,
      name: "object[document]",
      errorMessage: { text: "Document can't be blank" },
      classes: nil,
      hint: { text: hint },
      label: {
        text: label,
        classes: ""
      },
      attributes: {}
    }

    expect(template).to have_received(:govukFileUpload).with(expected_params)
  end
end
