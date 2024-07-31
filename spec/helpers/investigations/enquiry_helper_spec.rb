require "rails_helper"

RSpec.describe Investigations::EnquiryHelper, type: :helper do
  describe "#date_received" do
    let(:form) { instance_double(form) }

    it "renders the date input field with the correct parameters" do
      expect(helper).to receive(:govukDateInput).with(
        form:,
        key: :date_received,
        fieldset: { legend: { text: "When was it received?", classes: "govuk-fieldset__legend--m" } }
      )

      helper.date_received(form)
    end
  end

  describe "#received_type" do
    let(:form) { instance_double(form) }
    let(:expected_result) do
      [
        { text: "Email", value: "email" },
        { text: "Phone", value: "phone" },
        { text: "Other", value: "other", conditional: { html: helper.other_type(form) } }
      ]
    end

    it "returns the correct received types array" do
      allow(helper).to receive(:other_type).with(form).and_return("conditional_html")
      result = helper.received_type(form)

      expected_result[2][:conditional][:html] = "conditional_html"
      expect(result).to eq(expected_result)
    end
  end

  describe "#other_type" do
    let(:form) { instance_double(form) }
    let(:params) { { enquiry: { other_received_type: "test" } } }

    before do
      allow(helper).to receive(:params).and_return(params)
    end

    it "renders the input field with the correct parameters" do
      expect(helper).to receive(:govukInput).with(
        key: :other_received_type,
        value: "test",
        form:,
        label: { text: "Other received type", classes: "govuk-visually-hidden" }
      )

      helper.other_type(form)
    end
  end
end
