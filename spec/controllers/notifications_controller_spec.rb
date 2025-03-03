require "rails_helper"

RSpec.describe NotificationsController, :with_stubbed_mailer, type: :controller do
  let(:user) { create(:user, has_accepted_declaration: true, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let(:other_user) { create(:user, has_accepted_declaration: true, has_viewed_introduction: true, team: create(:team), roles: %w[notification_task_list_user]) }

  before do
    sign_in(user)
  end

  describe "GET #show" do
    context "when the notification is a draft" do
      let(:notification) { instance_double(Investigation::Notification, pretty_id: "1234", draft?: true) }

      before do
        allow(Investigation::Notification).to receive(:includes).and_return(Investigation::Notification)
        allow(Investigation::Notification).to receive(:find_by!).with(pretty_id: notification.pretty_id).and_return(notification)
      end

      shared_examples "redirects to notification creation workflow" do
        it "redirects to the notification creation workflow" do
          # Stub the policy to allow access to draft
          allow(controller).to receive(:policy).with(notification).and_return(
            instance_double(InvestigationPolicy, can_access_draft?: true)
          )

          get :show, params: { pretty_id: notification.pretty_id }
          expect(response).to redirect_to(notification_create_index_path(notification))
        end
      end

      context "when the user has access to the draft" do
        # This covers both creator and owner cases
        it_behaves_like "redirects to notification creation workflow"
      end

      context "when the user is neither the creator nor the owner" do
        before do
          sign_in(other_user)
        end

        it "returns a forbidden status" do
          # Stub the policy to deny access to draft
          allow(controller).to receive(:policy).with(notification).and_return(
            instance_double(InvestigationPolicy, can_access_draft?: false)
          )

          get :show, params: { pretty_id: notification.pretty_id }
          expect(response).to have_http_status(:forbidden)
        end

        it "renders the forbidden error page" do
          # Stub the policy to deny access to draft
          allow(controller).to receive(:policy).with(notification).and_return(
            instance_double(InvestigationPolicy, can_access_draft?: false)
          )

          get :show, params: { pretty_id: notification.pretty_id }
          expect(response).to render_template("errors/forbidden")
        end
      end
    end

    context "when the notification is submitted" do
      # Use a regular double instead of instance_double to avoid method verification
      let(:notification) { instance_double(Investigation::Notification, pretty_id: "1234", draft?: false) }
      let(:relation_double) { instance_double(ActiveRecord::Relation, order: []) }

      before do
        allow(Investigation::Notification).to receive(:includes).and_return(Investigation::Notification)
        allow(Investigation::Notification).to receive(:find_by!).with(pretty_id: notification.pretty_id).and_return(notification)
        # Stub any methods that might be called on the notification
        allow(notification).to receive_messages(
          to_param: notification.pretty_id,
          to_model: notification
        )
        allow(BulkProductsUpload).to receive(:where).and_return(relation_double)
      end

      it "renders the show template" do
        allow(user).to receive(:can_use_notification_task_list?).and_return(true)

        # Set up any additional stubs needed for the show action
        allow(controller).to receive_messages(
          breadcrumb_case_label: "Case",
          breadcrumb_case_path: "/"
        )

        get :show, params: { pretty_id: notification.pretty_id }
        expect(response).to be_successful
      end

      context "when the user cannot use notification task list" do
        let(:non_task_list_user) { create(:user, has_accepted_declaration: true, has_viewed_introduction: true, roles: []) }

        before do
          sign_in(non_task_list_user)
        end

        it "redirects to the investigation path" do
          # Ensure the current_user.can_use_notification_task_list? returns false
          allow(non_task_list_user).to receive(:can_use_notification_task_list?).and_return(false)

          get :show, params: { pretty_id: notification.pretty_id }
          expect(response).to redirect_to(investigation_path(notification))
        end
      end
    end
  end
end
