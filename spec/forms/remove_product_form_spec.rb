RSpec.describe RemoveProductForm do
  subject(:form)       { described_class.new(remove_product:, reason:) }

  let(:remove_product) { nil }
  let(:reason)         { nil }

  describe "remove_product validation" do
    context "when remove_product is blank" do
      it "is invalid" do
        expect(form).to be_invalid
      end
    end

    context "when remove_product is true" do
      let(:remove_product) { true }

      context "when reason is blank" do
        it "is invalid" do
          expect(form).to be_invalid
        end
      end

      context "when reason has a value" do
        let(:reason) { "just some reason" }

        it "is valid" do
          expect(form).to be_valid
        end

        it "persists remove_product value" do
          expect(form.remove_product).to eq true
        end

        it "persists reason value" do
          expect(form.reason).to eq reason
        end
      end
    end

    context "when remove_product is false" do
      let(:remove_product) { false }

      it "is valid" do
        expect(form).to be_valid
      end

      it "persists remove_product value" do
        expect(form.remove_product).to eq false
      end
    end
  end
end
