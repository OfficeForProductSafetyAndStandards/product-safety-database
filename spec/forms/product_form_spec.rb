require "rails_helper"

RSpec.describe ProductForm do
  subject(:form) { described_class.new(attributes) }

  let(:attributes) { attributes_for(:product, has_markings: false) }

  describe ".from" do
    let(:product) { build(:product_iphone) }

    it "populates the has_markings attribute" do
      expect(described_class.from(product).has_markings).to be true
    end
  end

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

  describe "markings validations" do
    let(:attributes) { attributes_for(:product).except(:markings) }

    context "when the question has not been answered" do
      it "is invalid", :aggregate_failures do
        expect(form).not_to be_valid
        expect(form.errors.full_messages_for(:has_markings)).to eq ["Select yes if the product has UKCA, UKNI or CE marking"]
      end
    end

    context "when the product has markings" do
      before { form.has_markings = true }

      context "when no markings have been selected" do
        it "is invalid", :aggregate_failures do
          expect(form).not_to be_valid
          expect(form.errors.full_messages_for(:markings)).to eq ["Select the product marking(s)"]
        end
      end

      context "when invalid markings are supplied" do
        before { form.markings = %w[invalid invalid2] }

        it "is invalid", :aggregate_failures do
          expect(form).not_to be_valid
          expect(form.errors.full_messages_for(:markings)).to eq ["Select the product marking(s)"]
        end
      end

      context "when valid markings have been supplied" do
        before { form.markings = [Product::MARKINGS.sample, Product::MARKINGS.sample] }

        it "is valid" do
          expect(form).to be_valid
        end
      end

      context "when a mix of valid and invalid markings have been supplied" do
        before { form.markings = [Product::MARKINGS.first, "invalid"] }

        it "is invalid", :aggregate_failures do
          expect(form).not_to be_valid
          expect(form.errors.full_messages_for(:markings)).to eq ["Select the product marking(s)"]
        end
      end

      context "when duplicate marking values have been supplied" do
        before { form.markings = [Product::MARKINGS.first, Product::MARKINGS.first] }

        it "is valid" do
          expect(form).to be_valid
        end

        it "de-duplicates the list" do
          expect(form.markings).to eq([Product::MARKINGS.first])
        end
      end
    end
  end
end
