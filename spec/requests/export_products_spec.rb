require "rails_helper"

RSpec.describe "Export products as XLSX file", :with_opensearch, :with_stubbed_mailer, :with_stubbed_notify, type: :request do
  let(:params) { {} }

  describe "#index as XLSX" do
    before do
      sign_in(user)
    end

    context "when logged in as a normal user" do
      let(:user) { create(:user, :activated, :viewed_introduction) }

      context "when generating a product export" do
        it "allows user to generate a product export and redirects back to products page" do
          get generate_product_exports_path

          expect(response).to have_http_status(:found)
        end
      end

      context "when viewing a product export" do
        it "allows user to generate a product export" do
          product_export = ProductExport.create!(user:, params:)
          get product_export_path(product_export)

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
