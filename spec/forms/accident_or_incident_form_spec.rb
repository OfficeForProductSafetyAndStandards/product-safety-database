require "rails_helper"

RSpec.describe AccidentOrIncidentForm, :with_test_queue_adapter do
  let(:investigation) { create(:allegation) }
  let(:user) { create(:user) }

  let(:date) { { day: "1", month: "2", year: "2020" } }
  let(:is_date_known) { "true" }
  let(:severity) { "serious" }
  let(:severity_other) { "" }
  let(:usage) { "during_normal_use" }
  let(:investigation_product_id) { create(:investigation_product).id }
  let(:type) { "accident" }

  let(:params) do
    {
      date:,
      is_date_known:,
      severity:,
      severity_other:,
      usage:,
      investigation_product_id:,
      type:
    }
  end

  let(:form) { described_class.new(params) }

  describe "validations" do
    context "with valid attributes" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    it_behaves_like "it does not allow far away dates", :date, nil, on_or_before: false

    context "with blank date" do
      context "with is_date_known == 'false'" do
        let(:date) { nil }
        let(:is_date_known) { "false" }

        it "is valid" do
          expect(form).to be_valid
        end
      end

      context "with is_date_known == 'true'" do
        let(:date) { nil }
        let(:is_date_known) { "true" }

        it "is not valid" do
          expect(form).not_to be_valid
        end
      end
    end

    context "when `is_date_known` is not `true` or `false`" do
      let(:is_date_known) { "" }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "when investigation_product_id is missing" do
      let(:investigation_product_id) { nil }

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
