require "rails_helper"

RSpec.describe ConfirmProductForm, :with_stubbed_opensearch, :with_stubbed_mailer do
  subject(:form) { described_class.new(product_id:, correct:) }

  let(:find_product_form) { FindProductForm.new(reference: product.id.to_s) }
  let(:product) { create(:product) }
  let(:product_id) { product.id.to_s }
  let(:correct) { "yes" }

  describe "from_find_product_form" do
    subject(:form) { described_class.from_find_product_form(find_product_form) }

    it "sets product_id correctly" do
      expect(form.product_id).to eq(product.id)
    end
  end

  describe "correct validation" do
    context "when correct is blank" do
      let(:correct) { "" }

      it "is invalid" do
        expect(form).to be_invalid
      end

      it "provides an error message" do
        form.valid?
        expect(form.errors.full_messages_for(:correct)).to eq ["Select yes if this is the correct product record to add to your case"]
      end
    end

    context "when correct is 'test'" do
      let(:correct) { "test" }

      it "is invalid" do
        expect(form).to be_invalid
      end

      it "provides an error message" do
        form.valid?
        expect(form.errors.full_messages_for(:correct)).to eq ["Select yes if this is the correct product record to add to your case"]
      end
    end

    context "when correct is 'yes'" do
      let(:correct) { "yes" }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "when correct is 'no'" do
      let(:correct) { "no" }

      it "is valid" do
        expect(form).to be_valid
      end
    end
  end

  describe "confirmed?" do
    it "returns true when correct is 'yes'" do
      expect(form.confirmed?).to eq(true)
    end

    context "when correct is 'no'" do
      let(:correct) { "no" }

      it "returns false" do
        expect(form.confirmed?).to eq(false)
      end
    end

    context "when correct is nil" do
      let(:correct) { nil }

      it "returns false" do
        expect(form.confirmed?).to eq(false)
      end
    end
  end

  describe "product finding" do
    context "when product_id matches an existing product id" do
      it "finds the existing product" do
        expect(form.product).to eq(product)
      end

      it "casts the product id" do
        expect(form.product_id).to eq(product.id)
      end
    end

    context "when product_id does not match an existing product id" do
      let(:product_id) { "1234" }

      it "casts the product id" do
        expect(form.product_id).to eq(1234)
      end

      it "raises an exception" do
        expect { form.product }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
