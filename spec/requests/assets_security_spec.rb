require "rails_helper"

RSpec.describe "Asset security", type: :request, with_stubbed_opensearch: true do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:other_team) { create(:team) }
  let(:investigation) { create(:allegation, :with_document, creator: user) }
  let(:document) do
    investigation.documents.first.update!(content_type: "image/png")
    investigation.documents.first
  end
  let(:other_user) { create(:user, :activated, has_viewed_introduction: true, team: other_team) }

  # rubocop:disable RSpec/NestedGroups
  context "when using generic active storage urls" do
    context "when using blobs redirect controller" do
      # /rails/active_storage/blobs/redirect/:signed_id/*filename(.:format)                                 active_storage/blobs/redirect#show
      # /rails/active_storage/blobs/:signed_id/*filename(.:format)                                          active_storage/blobs/redirect#show
      let(:redirect_url) { rails_service_blob_path(document.signed_id, filename: "xyz") }

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
      context "when the attachment is directly on an investigation" do
        context "when attachment is not an image" do
          before do
            sign_in(user)
            document.blob.update!(content_type: "pdf")
          end

          context "when the user's team owns the investigation" do
            it "returns file" do
              get asset_url
              expect(response.status).to eq(200)
            end
          end

          context "when user's team does not own the investigation" do
            before do
              sign_in(other_user)
            end

            context "when the user does not have the can_view_restricted_cases role" do
              it "does not return the file" do
                get asset_url
                expect(response).to redirect_to("/")
                expect(response.status).to eq(302)
              end
            end

            context "when user does have the can_view_restricted_cases role" do
              before do
                other_user.roles.create!(name: "restricted_case_viewer")
              end

              it "returns file" do
                get asset_url
                expect(response.status).to eq(200)
              end
            end
          end
        end

        context "when attachment is an image" do
          context "when the user's team owns to the investigation" do
            before do
              sign_in(user)
            end

            it "returns file" do
              get asset_url

              expect(response.status).to eq(200)
            end
          end

          context "when user's team does not own the investigation" do
            before do
              sign_in(other_user)
            end

            it "returns file" do
              get asset_url

              expect(response.status).to eq(200)
            end

            context "when the investigation is restricted" do
              before do
                investigation.update(is_private: true)
              end

              it "does not return file" do
                get asset_url
                expect(response).to redirect_to("/")
                expect(response.status).to eq(302)
              end
            end
          end
        end
      end

      context "when the attachment is an product" do
        let(:asset_url) { rails_storage_proxy_path(document) }
        let(:product) { create(:product, investigations: [investigation]) }

        before do
          document.update!(record_type: "Product", record_id: product.id)
          sign_in(user)
          get asset_url
        end

        context "when the user's team owns the product investigation" do
          it "returns file" do
            expect(response.status).to eq(200)
          end
        end

        context "when user's team does not own the product investigation" do
          it "returns file" do
            sign_in(other_user)
            expect(response.status).to eq(200)
          end
        end
      end

      context "when the attachment is an correspondence" do
        let(:asset_url) { rails_storage_proxy_path(document) }
        let(:correspondence) { create(:correspondence, investigation_id: investigation.id) }

        before do
          document.update!(record_type: "Correspondence", record_id: correspondence.id)
        end

        context "when the user's team has owns the correspondence investigation" do
          it "returns file" do
            sign_in(user)
            get asset_url
            expect(response.status).to eq(200)
          end
        end

        context "when user's team does not own to the correspondence investigation" do
          before do
            sign_in(other_user)
          end

          context "when the user does not have the can_view_restricted_cases role" do
            it "does not return the file" do
              get asset_url
              expect(response).to redirect_to("/")
              expect(response.status).to eq(302)
            end
          end

          context "when user does have the can_view_restricted_cases role" do
            before do
              other_user.roles.create!(name: "restricted_case_viewer")
            end

            it "returns file" do
              get asset_url
              expect(response.status).to eq(200)
            end
          end
        end
      end

      context "when the attachment is an test" do
        let(:asset_url) { rails_storage_proxy_path(document) }
        let(:test) { create(:test_result, investigation_id: investigation.id) }

        before do
          document.update!(record_type: "Test", record_id: test.id)
        end

        context "when the user's team owns the test investigation" do
          it "returns file" do
            sign_in(user)
            get asset_url
            expect(response.status).to eq(200)
          end
        end

        context "when user's team does not own to the test investigation" do
          before do
            sign_in(other_user)
          end

          it "returns the file" do
            get asset_url
            expect(response.status).to eq(200)
          end

          context "when the investigation is restricted" do
            before do
              investigation.update(is_private: true)
            end

            it "does not return file" do
              get asset_url
              expect(response).to redirect_to("/")
              expect(response.status).to eq(302)
            end
          end
        end
      end

      context "when the attachment is on an activity" do
        let(:asset_url) { rails_storage_proxy_path(document) }
        let(:product) { create(:product, investigations: [investigation]) }
        let(:investigation_product) { investigation.investigation_products.first }

        context "when the activity is not a correspondence or investigation document related" do
          let(:activity) { create(:audit_activity_test_result, investigation:, investigation_product:) }

          before do
            document.update!(record_type: "Activity", record_id: activity.id)
          end

          context "when the user's team owns the investigation" do
            it "returns file" do
              sign_in(user)
              get asset_url
              expect(response.status).to eq(200)
            end
          end

          context "when user's team does not own the investigation" do
            it "returns file" do
              sign_in(other_user)
              get asset_url
              expect(response.status).to eq(200)
            end
          end
        end

        context "when the activity is a correspondence" do
          let(:product) { create(:product, investigations: [investigation]) }
          let(:correspondence) { create(:correspondence_meeting, investigation:) }
          let(:investigation_product) { investigation.investigation_products.first }

          let!(:activity) { AuditActivity::Correspondence::Base.create(investigation:, investigation_product:, correspondence:) }

          before do
            document.update!(record_type: "Activity", record_id: activity.id)
          end

          context "when the user's team owns the investigation" do
            it "returns file" do
              sign_in(user)
              get asset_url
              expect(response.status).to eq(200)
            end
          end

          context "when user's team does not own the investigation" do
            it "returns file" do
              sign_in(other_user)
              get asset_url
              expect(response.status).to eq(302)
            end
          end
        end

        context "when the activity is related to a document" do
          let(:product) { create(:product, investigations: [investigation]) }
          let(:investigation_product) { investigation.investigation_products.first }
          let!(:activity) { AuditActivity::Document::Base.create(investigation:, investigation_product:) }

          before do
            document.update!(record_type: "Activity", record_id: activity.id)
          end

          context "when the document is an image" do
            context "when the user's team owns the investigation" do
              it "returns file" do
                sign_in(user)
                get asset_url
                expect(response.status).to eq(200)
              end
            end

            context "when user's team does not own the investigation" do
              it "returns file" do
                sign_in(other_user)
                get asset_url
                expect(response.status).to eq(200)
              end
            end
          end

          context "when the document is not an image" do
            before do
              document.blob.update!(content_type: "pdf")
            end

            context "when the user's team owns the investigation" do
              it "returns file" do
                sign_in(user)
                get asset_url
                expect(response.status).to eq(200)
              end
            end

            context "when user's team does not own the investigation" do
              context "when the user does not have the can_view_restricted_cases role" do
                it "does not return the file" do
                  sign_in(other_user)
                  get asset_url
                  expect(response).to redirect_to("/")
                  expect(response.status).to eq(302)
                end
              end

              context "when user does have the can_view_restricted_cases role" do
                before do
                  other_user.roles.create!(name: "restricted_case_viewer")
                end

                it "returns file" do
                  sign_in(other_user)
                  get asset_url
                  expect(response.status).to eq(200)
                end
              end
            end
          end
        end
      end

      context "when the attachment is a corrective_action" do
        let(:asset_url) { rails_storage_proxy_path(document) }
        let(:corrective_action) { create(:corrective_action, investigation_id: investigation.id) }

        before do
          document.update!(record_type: "CorrectiveAction", record_id: corrective_action.id)
        end

        context "when the user's team owns the corrective action investigation" do
          it "returns file" do
            sign_in(user)
            get asset_url
            expect(response.status).to eq(200)
          end
        end

        context "when user's team does not have own the corrective action investigation" do
          before do
            sign_in(other_user)
          end

          it "returns the file" do
            get asset_url
            expect(response.status).to eq(200)
          end

          context "when the investigation is restricted" do
            before do
              investigation.update(is_private: true)
            end

            it "does not return file" do
              get asset_url
              expect(response).to redirect_to("/")
              expect(response.status).to eq(302)
            end
          end
        end
      end
    end
  end
  # rubocop:enable RSpec/NestedGroups
end
