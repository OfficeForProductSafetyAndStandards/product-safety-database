RSpec.describe NotifyingCountryForm do
  subject(:form) { described_class.from(investigation) }

  let(:investigation) { build(:notification, notifying_country:) }
  let(:notifying_country) { "country:GB" }

  describe ".from" do
    it "sets the country" do
      expect(form.country).to eq("country:GB")
    end
  end

  describe "#valid?" do
    describe "when overseas_or_uk is blank" do
      before { form.validate }

      it "is not valid" do
        expect(form).to be_invalid
      end

      it "populates an error message" do
        expect(form.errors.full_messages_for(:overseas_or_uk)).to eq(["Select if the notifying country is overseas or in the UK"])
      end
    end

    context "when the overseas_or_uk is not blank" do
      context "when it is set to uk" do
        before { form.overseas_or_uk = "uk" }

        context "with notifying_country_uk set to blank" do
          before { form.validate }

          it "is not valid" do
            expect(form).to be_invalid
          end

          it "populates an error message" do
            expect(form.errors.full_messages_for(:notifying_country_uk)).to eq(["Enter the notifying country"])
          end
        end

        context "with notifying_country_uk filled in with a correct country" do
          before { form.notifying_country_uk = "country:GB-ENG" }

          it "is valid" do
            expect(form).to be_valid
          end
        end
      end
    end

    context "when it is set to overseas" do
      before { form.overseas_or_uk = "overseas" }

      context "with notifying_country_overseas set to blank" do
        before { form.validate }

        it "is not valid" do
          expect(form).to be_invalid
        end

        it "populates an error message" do
          expect(form.errors.full_messages_for(:notifying_country_overseas)).to eq(["Enter the notifying country"])
        end
      end

      context "with notifying_country_uk filled in with a correct country" do
        before { form.notifying_country_overseas = "country:FR" }

        it "is valid" do
          expect(form).to be_valid
        end
      end
    end
  end
end
