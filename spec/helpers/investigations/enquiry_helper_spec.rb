require "rails_helper"

class Form; end

RSpec.describe Investigations::EnquiryHelper, type: :helper do
  describe "#date_received" do
    let(:form) { instance_double(Form) }

    it "renders the date input field with the correct parameters" do
      allow(helper).to receive(:govukDateInput)
      helper.date_received(form)
      expect(helper).to have_received(:govukDateInput).with(
        form:,
        key: :date_received,
        fieldset: { legend: { text: "When was it received?", classes: "govuk-fieldset__legend--m" } }
      )
    end
  end

  describe "#received_type" do
    let(:form) { instance_double(Form) }
    let(:expected_result) do
      [
        { text: "Email", value: "email" },
        { text: "Phone", value: "phone" },
        { text: "Other", value: "other", conditional: { html: "conditional_html" } }
      ]
    end

    it "returns the correct received types array" do
      allow(helper).to receive(:other_type).with(form).and_return("conditional_html")
      result = helper.received_type(form)
      expect(result).to eq(expected_result)
    end
  end

  describe "#other_type" do
    let(:form) { instance_double(Form) }
    let(:params) { { enquiry: { other_received_type: "test" } } }

    before do
      allow(helper).to receive(:params).and_return(params)
      allow(helper).to receive(:govukInput)
    end

    it "renders the input field with the correct parameters" do
      helper.other_type(form)
      expect(helper).to have_received(:govukInput).with(
        key: :other_received_type,
        value: "test",
        form:,
        label: { text: "Other received type", classes: "govuk-visually-hidden" }
      )
    end
  end
end
