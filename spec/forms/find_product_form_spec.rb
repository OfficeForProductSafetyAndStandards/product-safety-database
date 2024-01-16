RSpec.describe FindProductForm, :with_stubbed_mailer do
  subject(:form) { described_class.new(reference:, investigation:) }

  let(:investigation) { create(:allegation) }
  let(:product) { create(:product) }

  describe "reference validation" do
    context "when reference is blank" do
      let(:reference) { "" }

      it "is invalid" do
        expect(form).to be_invalid
      end

      it "provides an error message" do
        form.valid?
        expect(form.errors.full_messages_for(:reference)).to eq ["Enter a PSD product record reference number"]
      end
    end

    context "when reference is the psd ref of a valid product" do
      let(:reference) { "psd-#{product.id}" }

      it "is valid" do
        expect(form).to be_valid
      end

      it "trims the 'psd-' prefix" do
        form.valid?
        expect(form.reference).to eq(product.id.to_s)
      end
    end

    context "when reference has leading and trailing spaces" do
      let(:reference) { "  #{product.id}  " }

      it "is valid" do
        expect(form).to be_valid
      end

      it "trims the 'psd-' prefix" do
        form.valid?
        expect(form.reference).to eq(product.id.to_s)
      end
    end

    context "when reference is the psd ref of a valid product, with capitalisation and spaces" do
      let(:reference) { "PsD-#{product.id} " }

      it "is valid" do
        expect(form).to be_valid
      end

      it "trims the 'psd-' prefix" do
        form.valid?
        expect(form.reference).to eq(product.id.to_s)
      end
    end

    context "when reference is the product id" do
      let(:reference) { product.id.to_s }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "when reference is a plausible but non-existing product id" do
      let(:reference) { "1234" }

      it "is invalid" do
        expect(form).to be_invalid
      end

      it "provides an error message" do
        form.valid?
        expect(form.errors.full_messages_for(:reference)).to eq ["An active product record matching psd-1234 does not exist"]
      end
    end

    context "when reference is not a number" do
      let(:reference) { "test" }

      it "is invalid" do
        expect(form).to be_invalid
      end

      it "provides an error message" do
        form.valid?
        expect(form.errors.full_messages_for(:reference)).to eq ["Enter a PSD product record reference number"]
      end
    end

    context "when reference is a decimal" do
      let(:reference) { "1.234" }

      it "is invalid" do
        expect(form).to be_invalid
      end

      it "provides an error message" do
        form.valid?
        expect(form.errors.full_messages_for(:reference)).to eq ["Enter a PSD product record reference number"]
      end
    end

    context "when reference is negative" do
      let(:reference) { "-1" }

      it "is invalid" do
        expect(form).to be_invalid
      end

      it "provides an error message" do
        form.valid?
        expect(form.errors.full_messages_for(:reference)).to eq ["Enter a PSD product record reference number"]
      end
    end

    context "with the product already added to the case" do
      context "when the investigation_products share the same investigation_closed_at date" do
        before do
          investigation.products << product
        end

        context "when reference is the product id" do
          let(:reference) { product.id.to_s }

          it "is invalid" do
            expect(form).to be_invalid
          end

          it "provides an error message" do
            form.valid?
            expect(form.errors.full_messages_for(:reference)).to eq ["Enter a product record which has not already been added to the notification"]
          end
        end
      end

      context "when the investigation_products have different investigation_closed_at date" do
        before do
          investigation.products << product
          investigation.investigation_products.first.update!(investigation_closed_at: Time.current)
        end

        context "when reference is the product id" do
          let(:reference) { product.id.to_s }

          it "is valid" do
            expect(form).to be_valid
          end
        end
      end
    end
  end

  describe "product finding" do
    context "when reference matches an existing product id" do
      let(:reference) { product.id.to_s }

      it "finds the existing product" do
        expect(form.product).to eq(product)
      end
    end

    context "when reference does not match an existing product id" do
      let(:reference) { "1234" }

      it "returns nil" do
        expect(form.product).to eq(nil)
      end
    end
  end
end
