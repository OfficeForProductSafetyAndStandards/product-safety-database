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
