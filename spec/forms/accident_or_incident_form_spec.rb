require "rails_helper"

RSpec.describe AccidentOrIncidentForm, :with_stubbed_elasticsearch, :with_test_queue_adapter do
  # Default set of valid attributes
  let(:investigation) { create(:allegation) }
  let(:user) { create(:user) }

  let(:date) { { day: "1", month: "2", year: "2020" } }
  let(:is_date_known) { "yes" }
  let(:severity) { "serious" }
  let(:severity_other) { "" }
  let(:usage) { "during_normal_use" }
  let(:product_id) { product.id }
  let(:type) { "accident" }
  let(:product) { create(:product) }

  let(:params) do
    {
      date: date,
      is_date_known: is_date_known,
      severity: severity,
      severity_other: severity_other,
      usage: usage,
      product_id: product_id,
      type: type
    }
  end

  let(:form) { described_class.new(params) }

  describe "validations" do
    context "with valid attributes" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "with blank date" do
      context "with is_date_known == 'no'" do
        let(:date) { nil }
        let(:is_date_known) { "no" }

        it "is valid" do
          expect(form).to be_valid
        end
      end

      context "with is_date_known == 'yes'" do
        let(:date) { nil }
        let(:is_date_known) { "yes" }

        it "is not valid" do
          expect(form).not_to be_valid
        end
      end
    end

    context "when `is_date_known` is not `yes` or `no`" do
      let(:is_date_known) { "" }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "when product_id is missing" do
      let(:product_id) { nil }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "when severity is missing" do
      let(:severity) { nil }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "when usage is missing" do
      let(:usage) { nil }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with severity_other is blank" do
      let(:severity_other) { nil }

      context "when severity is `other`" do
        let(:severity) { "other" }

        it "is not valid" do
          expect(form).not_to be_valid
        end
      end

      context "when severity is not `other`" do
        let(:severity) { "serious" }

        it "is valid" do
          expect(form).to be_valid
        end
      end
    end
  end
end
