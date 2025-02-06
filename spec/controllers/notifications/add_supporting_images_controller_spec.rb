require "rails_helper"

RSpec.describe Notifications::AddSupportingImagesController, :with_stubbed_mailer, type: :controller do
  include_context "with stubbed antivirus"
  let(:notification) { create(:notification) }
  let(:file) { fixture_file_upload("testImage.png", "image/png") }
  let(:image_upload) do
    upload = create(:image_upload, upload_model: notification)
    notification.update!(image_upload_ids: [upload.id])
    upload
  end
  let(:other_notification) { create(:notification) }
  let(:other_image) do
    upload = create(:image_upload, upload_model: other_notification)
    other_notification.update!(image_upload_ids: [upload.id])
    upload
  end
  let(:user) { create(:user, :activated) }
  let(:team) { create(:team) }

  before do
    user.team = team
    user.save!
    sign_in(user)
    notification.build_owner_collaborations_from(user)
    notification.save!
  end

  shared_examples "requires edit permission" do
    context "when user has read-only access" do
      before do
        other_user = create(:user, :activated)
        notification.owner_user_collaboration.destroy!
        notification.owner_team_collaboration.destroy!
        notification.build_owner_collaborations_from(other_user)
        notification.save!
        create(:read_only_collaboration, investigation: notification, collaborator: user.team)
        notification.reload
      end

      let(:request) { show_request }

      it "returns forbidden" do
        request
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET #show" do
    let(:show_request) { get :show, params: { notification_pretty_id: notification.pretty_id } }

    context "when notification is open" do
      it "renders the show template" do
        show_request
        expect(response).to render_template("notifications/add_supporting_images/add_supporting_images")
      end
    end

    context "when notification is closed" do
      before { notification.update!(is_closed: true) }

      it "redirects to the notification page" do
        show_request
        expect(response).to redirect_to(notification_path(notification))
        expect(flash[:warning]).to eq("Cannot edit a closed notification")
      end
    end

    include_examples "requires edit permission"
  end

  describe "POST #update" do
    let(:update_request) do
      post :update, params: {
        notification_pretty_id: notification.pretty_id,
        image_upload: { file_upload: file }
      }
    end

    context "when notification is open" do
      context "with valid params" do
        it "adds an image to the notification" do
          expect { update_request }.to change { notification.reload.image_upload_ids.count }.by(1)
            .and change(ImageUpload, :count).by(1)
        end

        it "redirects with success message" do
          update_request
          expect(response).to redirect_to(notification_add_supporting_images_path(notification))
          expect(flash[:success]).to eq("Supporting image uploaded successfully")
        end
      end

      context "with invalid params" do
        let(:file) { fixture_file_upload("test.txt", "text/plain") }

        it "does not create an image upload" do
          expect { update_request }.not_to(change(ImageUpload, :count))
        end

        it "renders the show template with error" do
          update_request
          expect(response).to render_template("notifications/add_supporting_images/add_supporting_images")
          expect(flash[:error]).to be_present
        end
      end
    end

    context "when notification is closed" do
      before { notification.update!(is_closed: true) }

      it "redirects with error" do
        update_request
        expect(response).to redirect_to(notification_path(notification))
        expect(flash[:warning]).to eq("Cannot edit a closed notification")
      end
    end
  end

  describe "GET #remove_upload" do
    let(:get_remove_upload_request) do
      get :remove_upload, params: {
        notification_pretty_id: notification.pretty_id,
        upload_id: image_upload.id
      }
    end

    context "when notification is open" do
      it "renders the remove_upload template" do
        get_remove_upload_request
        expect(response).to render_template(:remove_upload)
      end
    end

    context "when notification is closed" do
      before { notification.update!(is_closed: true) }

      it "redirects with error" do
        get_remove_upload_request
        expect(response).to redirect_to(notification_path(notification))
        expect(flash[:warning]).to eq("Cannot edit a closed notification")
      end
    end
  end

  describe "DELETE #remove_upload" do
    subject do
      delete :remove_upload, params: {
        notification_pretty_id: notification.pretty_id,
        upload_id: image_upload.id
      }
    end

    context "when notification is open" do
      let(:image_id) { image_upload.id }
      let(:notif) { notification }

      before do
        # Ensure the image is attached to the notification
        notif.image_upload_ids = [image_id]
        notif.save!
      end

      it "removes the image from the notification" do
        expect {
          delete :remove_upload, params: {
            notification_pretty_id: notif.pretty_id,
            upload_id: image_id
          }
        }.to change { notif.reload.image_upload_ids.count }.by(-1)
          .and change(ImageUpload, :count).by(-1)
      end

      it "redirects with success message" do
        delete :remove_upload, params: {
          notification_pretty_id: notification.pretty_id,
          upload_id: image_upload.id
        }

        expect(response).to redirect_to(notification_add_supporting_images_path(notification))
        expect(flash[:success]).to eq("Supporting image removed successfully")
      end

      it "handles attempts to remove non-existent images" do
        expect {
          delete :remove_upload, params: {
            notification_pretty_id: notification.pretty_id,
            upload_id: 999_999
          }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context "when trying to remove an image from another notification" do
        let(:other_notification) { create(:notification) }
        let(:other_image) do
          upload = create(:image_upload, upload_model: other_notification)
          other_notification.update!(image_upload_ids: [upload.id])
          upload
        end

        it "forbids removing images from other notifications" do
          delete :remove_upload, params: {
            notification_pretty_id: notification.pretty_id,
            upload_id: other_image.id
          }

          expect(other_notification.reload.image_upload_ids).to include(other_image.id)
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "when notification is closed" do
      before { notification.update!(is_closed: true) }

      let(:delete_request) do
        delete :remove_upload, params: {
          notification_pretty_id: notification.pretty_id,
          upload_id: image_upload.id
        }
      end

      it "redirects with error" do
        delete_request
        expect(response).to redirect_to(notification_path(notification))
        expect(flash[:warning]).to eq("Cannot edit a closed notification")
      end
    end
  end
end
