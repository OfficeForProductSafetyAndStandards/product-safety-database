require "rails_helper"

RSpec.describe ProductForm, :with_flipper do
  subject(:form) { described_class.new(attributes) }

  let(:attributes) { attributes_for(:product) }

  describe "country_of_origin validation" do
    before { form.country_of_origin = "" }

    it "is invalid", :aggregate_failures do
      expect(form).not_to be_valid
      expect(form.errors.full_messages_for(:country_of_origin)).to eq ["Country of origin cannot be blank"]
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

    context "when it an existing product", :with_stubbed_opensearch do
      subject(:form) { described_class.from(create(:product, authenticity:)) }

      context "when no authenticity was given" do
        let(:authenticity) { nil }

        it { is_expected.to be_authenticity_not_provided }
      end

      context "when an authenticity was given" do
        let(:authenticity) { Product.authenticities.keys.without("unsure").sample }

        it { is_expected.not_to be_authenticity_not_provided }
      end
    end
  end

  describe "#markings=" do
    context "when the value supplied is nil" do
      it "sets the value to an empty array" do
        form.markings = nil
        expect(form.attributes["markings"]).to eq([])
      end
    end

    context "when the value supplied is an Array" do
      context "when the value contains duplicates" do
        it "sets the value to an array with duplicates removed" do
          form.markings = [1, 1, 2]
          expect(form.attributes["markings"]).to eq([1, 2])
        end
      end
    end
  end

  describe "markings validations" do
    let(:attributes) { attributes_for(:product).except(:has_markings, :markings) }

    context "when the question has not been answered" do
      before { form.has_markings = nil }

      it "is invalid", :aggregate_failures do
        expect(form).not_to be_valid
        expect(form.errors.full_messages_for(:has_markings)).to eq ["Select yes if the product has UKCA, UKNI or CE marking"]
      end
    end

    context "when the product has markings" do
      before { form.has_markings = "markings_yes" }

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

  describe "category validations" do
    context "when the feature flag is on" do
      before do
        enable_feature(:new_taxonomy)
      end

      shared_examples "is invalid" do
        it "is invalid", :aggregate_failures do
          expect(form).not_to be_valid
          expect(form.errors.full_messages_for(:category)).to eq ["Select the main category"]
        end
      end

      context "when no category has been selected" do
        before do
          form.category = ""
        end

        it_behaves_like "is invalid"
      end

      context "when an invalid category has been selected" do
        before do
          form.category = "abc"
        end

        it_behaves_like "is invalid"
      end

      context "when a valid category has been selected" do
        let(:subcategory) { create(:product_subcategory) }

        before do
          form.category = subcategory.product_category.name
          form.subcategory = subcategory.name
        end

        it "is valid" do
          expect(form).to be_valid
        end
      end
    end

    context "when the feature flag is off" do
      before do
        disable_feature(:new_taxonomy)
      end

      context "when no category has been selected" do
        before do
          form.category = ""
        end

        it "is invalid", :aggregate_failures do
          expect(form).not_to be_valid
          expect(form.errors.full_messages_for(:category)).to eq ["Enter a valid product category"]
        end
      end

      context "when a category has been selected" do
        before do
          form.category = "PPE"
          form.subcategory = "PPE"
        end

        it "is valid" do
          expect(form).to be_valid
        end
      end
    end
  end

  describe "subcategory validations" do
    context "when the feature flag is on" do
      before do
        enable_feature(:new_taxonomy)
      end

      shared_examples "is invalid" do
        it "is invalid", :aggregate_failures do
          expect(form).not_to be_valid
          expect(form.errors.full_messages_for(:subcategory)).to eq ["Select the sub-category"]
        end
      end

      context "when no subcategory has been selected" do
        let(:category) { create(:product_category) }

        before do
          form.category = category.name
          form.subcategory = ""
        end

        it_behaves_like "is invalid"
      end

      context "when an invalid sub-category has been selected" do
        let(:category) { create(:product_category) }

        before do
          form.category = category.name
          form.subcategory = "abc"
        end

        it_behaves_like "is invalid"
      end

      context "when a valid subcategory has been selected" do
        let(:subcategory) { create(:product_subcategory) }

        before do
          form.category = subcategory.product_category.name
          form.subcategory = subcategory.name
        end

        it "is valid" do
          expect(form).to be_valid
        end
      end
    end

    context "when the feature flag is off" do
      before do
        disable_feature(:new_taxonomy)
      end

      context "when no subcategory has been entered" do
        before do
          form.subcategory = ""
        end

        it "is invalid", :aggregate_failures do
          expect(form).not_to be_valid
          expect(form.errors.full_messages_for(:subcategory)).to eq ["Enter a valid product subcategory"]
        end
      end

      context "when a subcategory has been entered" do
        before do
          form.category = "PPE"
          form.subcategory = "PPE"
        end

        it "is valid" do
          expect(form).to be_valid
        end
      end
    end
  end
end
