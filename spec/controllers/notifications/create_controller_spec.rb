require "rails_helper"

RSpec.describe Notifications::CreateController, :with_stubbed_mailer, type: :controller do
  let(:user) { create(:user, has_accepted_declaration: true, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let(:other_user) { create(:user, has_accepted_declaration: true, has_viewed_introduction: true, team: create(:team), roles: %w[notification_task_list_user]) }
  let(:notification) { create(:notification, creator_user: user, owner_user: user, state: "draft") }

  before do
    sign_in(user)
  end

  describe "before_action :set_notification" do
    context "when the notification is a draft" do
      context "when the user is the creator" do
        let(:notification) { create(:notification, creator_user: user, owner_user: user, state: "draft") }

        before do
          # Stub the find_by! method to return our notification
          allow(Investigation::Notification).to receive_messages(includes: Investigation::Notification, find_by!: notification)

          # Stub the policy to allow access to draft
          allow(controller).to receive(:policy).with(notification).and_return(
            instance_double(InvestigationPolicy, can_access_draft?: true)
          )

          # Stub the draft? method to return true to avoid redirect in disallow_changing_submitted_notification
          allow(notification).to receive(:draft?).and_return(true)
        end

        it "allows access to the index action" do
          get :index, params: { notification_pretty_id: notification.pretty_id }
          expect(response).to be_successful
        end
      end

      context "when the user is the owner but not the creator" do
        let(:notification) { create(:notification, creator_user: other_user, owner_user: user, state: "draft") }

        before do
          # Stub the find_by! method to return our notification
          allow(Investigation::Notification).to receive_messages(includes: Investigation::Notification, find_by!: notification)

          # Stub the policy to allow access to draft
          allow(controller).to receive(:policy).with(notification).and_return(
            instance_double(InvestigationPolicy, can_access_draft?: true)
          )

          # Stub the draft? method to return true to avoid redirect in disallow_changing_submitted_notification
          allow(notification).to receive(:draft?).and_return(true)
        end

        it "allows access to the index action" do
          get :index, params: { notification_pretty_id: notification.pretty_id }
          expect(response).to be_successful
        end
      end

      context "when the user is neither the creator nor the owner" do
        let(:notification) { create(:notification, creator_user: user, owner_user: user, state: "draft") }

        before do
          sign_in(other_user)

          # Stub the find_by! method to return our notification
          allow(Investigation::Notification).to receive_messages(includes: Investigation::Notification, find_by!: notification)

          # Stub the policy to deny access to draft
          allow(controller).to receive(:policy).with(notification).and_return(
            instance_double(InvestigationPolicy, can_access_draft?: false)
          )

          # Skip the disallow_changing_submitted_notification method to avoid double render
          allow(controller).to receive(:disallow_changing_submitted_notification)
        end

        it "returns a forbidden status" do
          get :index, params: { notification_pretty_id: notification.pretty_id }
          expect(response).to have_http_status(:forbidden)
        end

        it "renders the forbidden error page" do
          get :index, params: { notification_pretty_id: notification.pretty_id }
          expect(response).to render_template("errors/forbidden")
        end
      end
    end

    context "when the notification is submitted" do
      let(:notification) { create(:notification, creator_user: user, owner_user: user, state: "submitted") }

      before do
        # Stub the find_by! method to return our notification
        allow(Investigation::Notification).to receive_messages(includes: Investigation::Notification, find_by!: notification)

        # Stub the draft? method to return false to trigger redirect in disallow_changing_submitted_notification
        allow(notification).to receive(:draft?).and_return(false)
      end

      it "redirects to the notification path" do
        get :index, params: { notification_pretty_id: notification.pretty_id }
        expect(response).to redirect_to(notification_path(notification))
      end
    end
  end
end
