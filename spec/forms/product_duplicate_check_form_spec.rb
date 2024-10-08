require "rails_helper"

RSpec.describe ProductDuplicateCheckForm do
  subject(:form) { described_class.new(params) }

  let(:params) { {} }

  context "when a barcode with spaces is provided" do
    let(:params) { { has_barcode: true, barcode: " 1234567890123  " } }

    it { is_expected.to be_valid }

    it "strips leading spaces" do
      form.valid?
      expect(form.barcode).to eq "1234567890123"
    end
  end

  context "when has_barcode is false" do
    let(:params) { { has_barcode: false } }

    it { is_expected.to be_valid }

    context "when barcode is provided & invalid" do
      let(:params) { { has_barcode: false, barcode: "ddd" } }

      it "does not validate barcode" do
        expect(form).to be_valid
      end
    end
  end

  context "when has_barcode is true" do
    context "when barcode is not provided" do
      let(:params) { { has_barcode: true } }

      it { is_expected.not_to be_valid }
    end

    context "when barcode is provided" do
      before { form.valid? }

      context "when barcode has dashes in" do
        let(:params) { { has_barcode: true, barcode: "1234-56789-0123" } }

        it { is_expected.to be_valid }

        it "persists has_barcode value" do
          expect(form.has_barcode).to be true
        end

        it "persists barcode value" do
          expect(form.barcode).to eq "1234-56789-0123"
        end
      end

      context "when barcode has brackets and non-numerics in" do
        let(:params) { { has_barcode: true, barcode: "1234-56789(0123)" } }

        it { is_expected.to be_valid }

        it "persists has_barcode value" do
          expect(form.has_barcode).to be true
        end

        it "persists barcode value" do
          expect(form.barcode).to eq "1234-56789(0123)"
        end
      end

      context "when barcode breaks the character limit before stripping out blank space" do
        let(:params) { { has_barcode: true, barcode: "          1234-56789(0123)          " } }

        it { is_expected.to be_valid }

        it "persists has_barcode value" do
          expect(form.has_barcode).to be true
        end

        it "persists barcode value" do
          expect(form.barcode).to eq "1234-56789(0123)"
        end
      end

      context "when barcode is valid" do
        let(:params) { { has_barcode: true, barcode: "1234567890123" } }

        it { is_expected.to be_valid }

        it "persists has_barcode value" do
          expect(form.has_barcode).to be true
        end

        it "persists barcode value" do
          expect(form.barcode).to eq "1234567890123"
        end
      end
    end
  end

  context "when no has_barcode is provided" do
    it { is_expected.not_to be_valid }
  end
end
