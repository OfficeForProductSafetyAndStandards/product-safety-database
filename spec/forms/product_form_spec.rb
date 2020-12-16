require "rails_helper"

RSpec.describe ProductForm do
  subject(:form) { described_class.new(attributes) }

  let(:attributes) { attributes_for(:product) }

  describe "gtin13 validations" do
    context "when setting an empty string" do
      before { form.gtin13 = "" }

      it "gets converted to nil on validation", :aggregate_failures do
        expect(form).to be_valid
        expect(form.gtin13).to be_nil
      end
    end

    context "when setting nil" do
      before { form.gtin13 = nil }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "when setting an invalid alphanumeric code" do
      before { form.gtin13 = "ABC123" }

      it "is invalid", :aggregate_failures do
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq(["Enter a valid barcode number"])
      end
    end

    context "when setting a 8 digit UPC-A code" do
      before { form.gtin13 = "40123455" }

      it "accepts a 8 digit code", :aggregate_failures do
        expect(form).to be_valid
        expect(form.gtin13).to eq "0000040123455"
      end
    end

    context "when setting a 12 digit UPC-A code" do
      before { form.gtin13 = "012345678912" }

      it "gets converted to a 13 digit code on validation", :aggregate_failures do
        expect(form).to be_valid
        expect(form.gtin13).to eq "0012345678912"
      end
    end

    context "when setting a 13 digit EAN code with a trailing space" do
      before { form.gtin13 = "0012345678912 " }

      it "gets its trailing space removed on validation", :aggregate_failures do
        expect(form).to be_valid
        expect(form.gtin13).to eq "0012345678912"
      end
    end

    context "when setting a 14 digit GTIN number" do
      before { form.gtin13 = "00016000275263" }

      it "gets converted to a 13 digit code on validation", :aggregate_failures do
        expect(form).to be_valid
        expect(form.gtin13).to eq "0016000275263"
      end
    end
  end

  describe "brand validation" do
    context "when setting an empty string" do
      before { form.brand = " " }

      it "gets converted to nil on validation", :aggregate_failures do
        expect(form).to be_valid
        expect(form.brand).to be_nil
      end
    end

    context "when setting as a non-empty string" do
      before { form.brand = " MyBrand " }

      it "is valid and whitespace is trimmed", :aggregate_failures do
        expect(form).to be_valid
        expect(form.brand).to eq "MyBrand"
      end
    end
  end

  describe "authenticity validation" do
    before { form.authenticity = "invalid authenticity" }

    it "is invalid", :aggregate_failures do
      expect(form).not_to be_valid
      expect(form.errors.full_messages_for(:authenticity)).to eq ["You must state whether the product is a counterfeit"]
    end
  end

  describe "#authenticity_not_provided?" do
    context "when it is a new object" do
      it { is_expected.not_to be_authenticity_not_provided }
    end

    context "when it an existing product", :with_stubbed_elasticsearch do
      subject(:form) { described_class.from(create(:product, authenticity: authenticity)) }

      context "when no authenticity was given" do
        let(:authenticity) { nil }

        it { is_expected.to be_authenticity_not_provided }
      end

      context "when an authenticity was given" do
        let(:authenticity) { Product.authenticities.keys.sample }

        it { is_expected.not_to be_authenticity_not_provided }
      end
    end
  end
end
