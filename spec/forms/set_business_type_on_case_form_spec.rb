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
          online_marketplace_id:,
          other_marketplace_name: nil
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

    context "when type is authorised_representative" do
      let(:type) { "authorised_representative" }
      let(:authorised_representative_choice) { "eu" }
      let(:params) do
        {
          type:,
          authorised_representative_choice:,
        }
      end

      it "is valid" do
        expect(form).to be_valid
      end

      context "when authorised_representative_choice is missing" do
        let(:authorised_representative_choice) { nil }

        it "is invalid with an invalid authorised_representative_choice" do
          expect(form).not_to be_valid
          expect(form.errors[:authorised_representative_choice]).to include("Select an authorised representative region")
        end
      end
    end
  end

  describe "#is_approved_online_marketplace?" do
    context "when type is online_marketplace" do
      let(:type) { "online_marketplace" }

      context "when an other_marketplace_name is provided (unapproved marketplace)" do
        let(:other_marketplace_name) { "Other marketplace" }
        let(:params) do
          {
            type:,
            online_marketplace_id: nil,
            other_marketplace_name:
          }
        end

        it "returns false" do
          expect(form).to be_valid
          expect(form).not_to be_is_approved_online_marketplace
        end
      end

      context "when an other_marketplace_name is not provided" do
        let(:online_marketplace_id) { "123" }
        let(:params) do
          {
            type:,
            online_marketplace_id:
          }
        end

        it "returns true" do
          expect(form).to be_valid
          expect(form).to be_is_approved_online_marketplace
        end
      end
    end

    context "when type is not online_marketplace" do
      let(:type) { "retailer" }

      it "returns false" do
        expect(form).to be_valid
        expect(form).not_to be_is_approved_online_marketplace
      end
    end
  end

  describe "#approved_online_marketplace" do
    let(:type) { "online_marketplace" }
    let(:params) do
      {
        type:,
        online_marketplace_id:
      }
    end

    context "when online_marketplace_id is blank" do
      let(:online_marketplace_id) { nil }

      it "throws an exception" do
        expect { form.approved_online_marketplace }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when online_marketplace_id resolves to an online marketplace" do
      let(:online_marketplace) { create(:online_marketplace, :approved) }
      let(:online_marketplace_id) { online_marketplace.id }

      it "returns the object" do
        expect(form.approved_online_marketplace).to eq(online_marketplace)
      end
    end

    context "when online_marketplace_id resolves to an unapproved marketplace" do
      let(:online_marketplace) { create(:online_marketplace, approved_by_opss: false) }
      let(:online_marketplace_id) { online_marketplace.id }

      it "throws an exception" do
        expect { form.approved_online_marketplace }.to raise_error(ActiveRecord::RecordNotFound)
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

  describe "#clear_params_from_session" do
    subject(:clear_params_from_session) do
      form.clear_params_from_session(session)
    end

    let!(:session) do
      {
        business_type: "retailer",
        online_marketplace_id: "123",
        other_marketplace_name: "Other marketplace"
      }
    end

    it "clears the business_type, online_marketplace_id and other_marketplace_name from the session", :aggregate_failures do
      clear_params_from_session

      expect(session[:business_type]).to be_nil
      expect(session[:online_marketplace_id]).to be_nil
      expect(session[:other_marketplace_name]).to be_nil
    end
  end
end
