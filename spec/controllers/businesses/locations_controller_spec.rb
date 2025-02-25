require "rails_helper"

RSpec.describe Businesses::LocationsController, type: :controller do
  let(:user) { create(:user, :activated) }
  let(:business) { create(:business) }

  before do
    sign_in(user)
    request.host = "example.org"
  end

  describe "POST #create" do
    context "with valid params" do
      let(:valid_params) do
        {
          business_id: business.id,
          location: {
            name: "Head Office",
            country: "country:GB",
            address_line_1: "123 Test St",
            city: "London",
            postal_code: "SW1A 1AA"
          }
        }
      end

      it "creates a new location" do
        expect {
          post :create, params: valid_params
        }.to change(Location, :count).by(1)
      end

      it "redirects to the business page" do
        post :create, params: valid_params
        expect(response).to redirect_to(business_url(business, anchor: "locations", only_path: true))
      end

      it "sets a success flash message" do
        post :create, params: valid_params
        expect(flash[:success]).to eq("Location was successfully created.")
      end

      it "assigns the current user as added_by_user" do
        post :create, params: valid_params
        expect(Location.last.added_by_user).to eq(user)
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          business_id: business.id,
          location: {
            name: "", # Required field
            country: "", # Required field
            address_line_1: "123 Test St",
            city: "London",
            postal_code: "SW1A 1AA"
          }
        }
      end

      it "does not create a new location" do
        expect {
          post :create, params: invalid_params
        }.not_to change(Location, :count)
      end

      it "returns unprocessable_entity status" do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders the new template" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end

      it "sets validation errors on the location" do
        post :create, params: invalid_params
        expect(assigns(:location).errors[:name]).to include("Name cannot be blank")
        expect(assigns(:location).errors[:country]).to include("Country cannot be blank")
      end
    end
  end
end
