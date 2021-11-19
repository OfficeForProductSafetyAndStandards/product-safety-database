require "rails_helper"

RSpec.describe "Asset security", type: :request, with_stubbed_elasticsearch: true do
  let!(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let!(:other_team) { create(:team) }
  let(:investigation) { create(:allegation, :with_document, creator: user) }
  let!(:document) { investigation.documents.first }

  context "when using generic active storage urls" do
    context "when using blobs redirect controller" do
      # /rails/active_storage/blobs/redirect/:signed_id/*filename(.:format)                                 active_storage/blobs/redirect#show
      # /rails/active_storage/blobs/:signed_id/*filename(.:format)                                          active_storage/blobs/redirect#show
      let(:redirect_url) { rails_blob_path(document) }

      it "redirects" do
        get redirect_url

        expect(response).to redirect_to("/")
      end
    end

    context "when using representations redirect controller" do
      # /rails/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename(.:format)   active_storage/representations/redirect#show
      # /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format)            active_storage/representations/redirect#show
      let(:redirect_url) { rails_blob_representation_path(document, filename: "xyz", variation_key: "foo") }

      it "redirects" do
        get redirect_url

        expect(response).to redirect_to("/")
      end
    end
  end

  # rubocop:disable RSpec/MultipleExpectations
  context "when using representations proxy controller" do
    # /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)      active_storage/representations/proxy#show
    let(:asset_url) { rails_storage_proxy_path(document) }

    context "when user is not logged in" do
      it "redirects to sign in page" do
        get asset_url

        expect(response).to redirect_to("/sign-in")
        expect(response.status).to eq(302)
      end
    end

    context "when user is logged in" do
      before do
        sign_in(user)
      end

      it "returns file" do
        get asset_url
        expect(response.content_type).to eq(document.blob.content_type)
        expect(response.status).to eq(200)
      end
    end
  end

  context "when using blob asset proxy controller" do
    let(:asset_url) { rails_storage_proxy_path(document) }

    context "when user is not logged in" do
      it "redirects to sign in page" do
        get asset_url

        expect(response).to redirect_to("/sign-in")
        expect(response.status).to eq(302)
      end
    end

    context "when user is logged in" do
      context "when the attachment is an investigation" do
        context "when the user has access to the investigation" do
          before do
            sign_in(user)
          end

          it "returns file" do
            get asset_url
            expect(response.content_type).to eq(document.blob.content_type)
            expect(response.status).to eq(200)
          end
        end

        context "when user does not have access to the investigation" do
          let(:other_user) { create(:user, :activated, has_viewed_introduction: true, team: other_team) }

          before do
            sign_in(other_user)
          end

          it "returns file" do
            get asset_url
            expect(response).to redirect_to("/")
            expect(response.status).to eq(302)
          end
        end
      end

      context "when the attachment is an product" do
        let(:asset_url) { rails_storage_proxy_path(document) }
        let(:product) { create(:product, investigations: [investigation]) }

        before do
          document.update!(record_type: "Product", record_id: product.id)
        end

        context "when the user has access to the product" do
          it "returns file" do
            sign_in(user)
            get asset_url
            expect(response.content_type).to eq(document.blob.content_type)
            expect(response.status).to eq(200)
          end
        end

        context "when user does not have access to the product" do
          let(:other_user) { create(:user, :activated, has_viewed_introduction: true, team: other_team) }

          it "returns file" do
            sign_in(other_user)
            get asset_url
            expect(response).to redirect_to("/")
            expect(response.status).to eq(302)
          end
        end
      end
    end
  end
  # rubocop:enable RSpec/MultipleExpectations
end
