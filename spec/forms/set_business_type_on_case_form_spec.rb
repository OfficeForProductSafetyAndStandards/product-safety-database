require "rails_helper"

RSpec.describe SetBusinessTypeOnCaseForm, type: :model do
  subject(:form) { described_class.new(params) }

  let(:type) { "retailer" }
  let(:params) do
    {
      type:
    }
  end

  describe "validations" do
    it "is valid with a valid type" do
      expect(form).to be_valid
    end

    context "when type is missing" do
      let(:type) { nil }

      it "is invalid with an invalid type" do
        expect(form).not_to be_valid
        expect(form.errors[:type]).to include("Select a business type")
      end
    end

    context "when type is not in the list" do
      let(:type) { "invalid" }

      it "is invalid with an invalid type" do
        expect(form).not_to be_valid
        expect(form.errors[:type]).to include("Select a business type")
      end
    end

    context "when type is online_marketplace" do
      let(:type) { "online_marketplace" }
      let(:online_marketplace_id) { "123" }
      let(:params) do
        {
          type:,
          online_marketplace_id:
        }
      end

      context "when online_marketplace_id is missing" do
        let(:online_marketplace_id) { nil }

        it "is invalid with an invalid online_marketplace_id" do
          expect(form).not_to be_valid
          expect(form.errors[:online_marketplace_id]).to include("Select an online marketplace")
        end

        context "when an other_marketplace_name is provided" do
          let(:other_marketplace_name) { "Other marketplace" }
          let(:params) do
            {
              type:,
              online_marketplace_id:,
              other_marketplace_name:
            }
          end

          it "is valid" do
            expect(form).to be_valid
          end
        end
      end
    end
  end

  describe "#set_params_on_session" do
    context "when type is online_marketplace" do
      let(:type) { "online_marketplace" }
      let(:online_marketplace_id) { "123" }
      let(:params) do
        {
          type:,
          online_marketplace_id:
        }
      end

      it "sets the type and online_marketplace_id on the session" do
        session = {}
        form.set_params_on_session(session)
        expect(session[:business_type]).to eq(type)
        expect(session[:online_marketplace_id]).to eq(online_marketplace_id)
      end

      context "when an other_marketplace_name is provided" do
        let(:other_marketplace_name) { "Other marketplace" }
        let(:params) do
          {
            type:,
            online_marketplace_id: nil,
            other_marketplace_name:
          }
        end

        it "sets the type and other_marketplace_name on the session" do
          session = {}
          form.set_params_on_session(session)
          expect(session[:business_type]).to eq(type)
          expect(session[:other_marketplace_name]).to eq(other_marketplace_name)
        end
      end
    end

    context "when type is not online_marketplace" do
      let(:type) { "retailer" }
      let(:params) do
        {
          type:
        }
      end

      it "sets the type on the session" do
        session = {}
        form.set_params_on_session(session)
        expect(session[:business_type]).to eq(type)
        expect(session[:online_marketplace_id]).to be_nil
      end
    end
  end
end
