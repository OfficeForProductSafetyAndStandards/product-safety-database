require "rails_helper"

RSpec.describe "Export products as XLSX file", :with_elasticsearch, :with_stubbed_notify, :with_stubbed_mailer, type: :request do
  describe "#index as XLSX" do
    before do
      sign_in(user)
    end

    context "when logged in as a normal user" do
      let(:user) { create(:user, :activated, :viewed_introduction) }

      context "generating a product export" do
        it "shows a forbidden error", :with_errors_rendered, :aggregate_failures do
          get generate_product_exports_path

          expect(response).to render_template("errors/forbidden")
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "viewing a product export" do
        it "shows a forbidden error", :with_errors_rendered, :aggregate_failures do
          product_export = ProductExport.create!
          get product_export_path(product_export)

          expect(response).to render_template("errors/forbidden")
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "when logged in as a user with the psd_admin role" do
      let(:user) { create(:user, :activated, :psd_admin, :viewed_introduction) }

      context "generating a product export" do
        it "allows user to generate a product export and redirects back to products page" do
          get generate_product_exports_path

          expect(response).to have_http_status(:found)
        end
      end

      context "viewing a product export" do
        it "allows user to generate a product export" do
          product_export = ProductExport.create!
          get product_export_path(product_export)

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
