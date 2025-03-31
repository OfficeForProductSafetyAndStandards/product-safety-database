require "rails_helper"

RSpec.describe Notifications::RecordACorrectiveActionController, :with_stubbed_antivirus, :with_stubbed_mailer, type: :controller do
  let(:creator_user) { create(:user, :activated, :opss_user, team: creator_team) }
  let(:owner_user) { create(:user, :activated, :opss_user, team: owner_team) }
  let(:creator_team) { create(:team) }
  let(:owner_team) { create(:team) }
  let(:edit_access_team) { create(:team) }
  let(:read_only_team) { create(:team) }
  let(:notification) do
    create(:notification,
           creator: creator_user,
           creator_team: creator_team,
           edit_access_teams: [edit_access_team],
           read_only_teams: [read_only_team]).tap do |n|
      n.owner_user = owner_user
      n.owner_team = owner_team
      n.save!
    end
  end
  let(:investigation_product) { create(:investigation_product, investigation: notification) }
  let(:business) { create(:business) }
  let(:corrective_action) { create(:corrective_action, investigation: notification) }
  let(:valid_params) do
    {
      notification_pretty_id: notification.pretty_id,
      corrective_action: {
        action: "mandatory_recall",
        "date_decided(3i)": "10",
        "date_decided(2i)": "3",
        "date_decided(1i)": "2025",
        legislation: ["General Product Safety Regulations 2005"],
        measure_type: "Mandatory",
        duration: "permanent",
        geographic_scopes: ["Great Britain"],
        details: "Test details",
        investigation_product_id: investigation_product.id,
        business_id: business.id,
        has_online_recall_information: "has_online_recall_information_no"
      }
    }
  end
  let(:invalid_params) do
    {
      notification_pretty_id: notification.pretty_id,
      corrective_action: {
        action: "mandatory_recall",
        "date_decided(3i)": "",
        "date_decided(2i)": "",
        "date_decided(1i)": "",
        legislation: ["General Product Safety Regulations 2005"],
        measure_type: "Mandatory",
        duration: "permanent",
        geographic_scopes: ["Great Britain"],
        details: "Test details",
        investigation_product_id: investigation_product.id,
        business_id: business.id,
        has_online_recall_information: "has_online_recall_information_no"
      }
    }
  end

  before do
    sign_in(creator_user)
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: { notification_pretty_id: notification.pretty_id }
      expect(response).to be_successful
    end

    it "initializes a new corrective action form" do
      get :new, params: { notification_pretty_id: notification.pretty_id }
      expect(assigns(:corrective_action_form)).to be_a(CorrectiveActionForm)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      let(:service_result) { instance_double(Interactor::Context, success?: true) }
      let(:corrective_action_form) { instance_double(CorrectiveActionForm, valid?: true, serializable_hash: {}) }

      before do
        allow(CorrectiveActionForm).to receive(:new).and_return(corrective_action_form)
        allow(corrective_action_form).to receive(:date_decided=)
        allow(corrective_action_form).to receive(:cache_file!)
        allow(AddCorrectiveActionToNotification).to receive(:call).and_return(service_result)
      end

      it "creates a new corrective action" do
        post :create, params: valid_params
        expect(AddCorrectiveActionToNotification).to have_received(:call).with(
          hash_including(user: creator_user, notification: notification)
        )
      end

      it "sets the date fields correctly" do
        post :create, params: valid_params
        expect(corrective_action_form).to have_received(:date_decided=).with(
          { year: "2025", month: "3", day: "10" }
        )
      end

      it "redirects to the notification page" do
        post :create, params: valid_params
        expect(response).to redirect_to(notification_path(notification))
      end
    end

    context "with invalid params" do
      before do
        # Create a form that will fail validation
        corrective_action_form = instance_double(CorrectiveActionForm, valid?: false)
        allow(CorrectiveActionForm).to receive(:new).and_return(corrective_action_form)
        allow(corrective_action_form).to receive(:date_decided=)
        allow(corrective_action_form).to receive(:cache_file!)
        # Spy on the service object
        allow(AddCorrectiveActionToNotification).to receive(:call)
      end

      it "does not create a new corrective action" do
        # Service should not be called if form is invalid
        post :create, params: invalid_params
        expect(AddCorrectiveActionToNotification).not_to have_received(:call)
      end

      it "renders the new template" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      get :edit, params: { notification_pretty_id: notification.pretty_id, id: corrective_action.id }
      expect(response).to be_successful
    end

    it "assigns the requested corrective action form" do
      get :edit, params: { notification_pretty_id: notification.pretty_id, id: corrective_action.id }
      expect(assigns(:corrective_action_form)).to be_a(CorrectiveActionForm)
    end
  end

  describe "PATCH #update" do
    let(:update_params) do
      {
        notification_pretty_id: notification.pretty_id,
        id: corrective_action.id,
        corrective_action: {
          action: "mandatory_recall",
          "date_decided(3i)": "15",
          "date_decided(2i)": "3",
          "date_decided(1i)": "2025",
          legislation: ["General Product Safety Regulations 2005"],
          measure_type: "Mandatory",
          duration: "permanent",
          geographic_scopes: ["Great Britain"],
          details: "Updated details",
          investigation_product_id: investigation_product.id,
          business_id: business.id,
          has_online_recall_information: "has_online_recall_information_no"
        }
      }
    end

    context "with valid params" do
      let(:corrective_action_form) { instance_double(CorrectiveActionForm, valid?: true, serializable_hash: {}, changes: {}) }

      before do
        allow(CorrectiveActionForm).to receive(:new).and_return(corrective_action_form)
        allow(corrective_action_form).to receive(:date_decided=)
        allow(corrective_action_form).to receive(:cache_file!)
        allow(corrective_action_form).to receive_messages(action: "mandatory_recall", has_online_recall_information: "has_online_recall_information_no", online_recall_information: nil, date_decided: { year: "2025", month: "3", day: "15" }, legislation: ["General Product Safety Regulations 2005"], business_id: business.id, measure_type: "Mandatory", duration: "permanent", geographic_scopes: ["Great Britain"], details: "Updated details", related_file: nil, document: nil)
        allow(UpdateCorrectiveAction).to receive(:call!)
      end

      it "updates the requested corrective action" do
        patch :update, params: update_params
        expect(UpdateCorrectiveAction).to have_received(:call!).with(
          hash_including(corrective_action: corrective_action, details: "Updated details", user: creator_user)
        )
      end

      it "sets the date fields correctly" do
        patch :update, params: update_params
        expect(corrective_action_form).to have_received(:date_decided=).with(
          { year: "2025", month: "3", day: "15" }
        )
      end

      it "redirects to the notification page" do
        patch :update, params: update_params
        expect(response).to redirect_to(notification_path(notification))
      end
    end

    context "with invalid params" do
      let(:invalid_update_params) do
        {
          notification_pretty_id: notification.pretty_id,
          id: corrective_action.id,
          corrective_action: {
            action: "mandatory_recall",
            "date_decided(3i)": "",
            "date_decided(2i)": "",
            "date_decided(1i)": "",
            legislation: ["General Product Safety Regulations 2005"],
            measure_type: "Mandatory",
            duration: "permanent",
            geographic_scopes: ["Great Britain"],
            details: "Updated details",
            investigation_product_id: investigation_product.id,
            business_id: business.id,
            has_online_recall_information: "has_online_recall_information_no"
          }
        }
      end

      it "does not update the corrective action" do
        original_details = corrective_action.details
        patch :update, params: invalid_update_params
        corrective_action.reload
        expect(corrective_action.details).to eq(original_details)
      end

      it "renders the edit template" do
        patch :update, params: invalid_update_params
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "#set_notification_breadcrumbs" do
    before do
      # Mock the breadcrumb method to verify it's called with the correct arguments
      allow(controller).to receive(:breadcrumb)
      get :new, params: { notification_pretty_id: notification.pretty_id }
    end

    it "sets the home breadcrumb" do
      expect(controller).to have_received(:breadcrumb).with("notifications.label", :your_notifications)
    end

    it "sets the notifications search breadcrumb" do
      expect(controller).to have_received(:breadcrumb).with("All notifications - Search", :notifications_path)
    end

    it "sets the notification breadcrumb" do
      expect(controller).to have_received(:breadcrumb).with(notification.pretty_id, notification_path(notification))
    end
  end

  # Verifies the controller's authorization logic to ensure proper access control
  describe "authorization validation" do
    let(:other_user) { create(:user, :activated, :opss_user) }

    shared_examples "forbidden access" do
      it "returns forbidden status for new action" do
        get :new, params: { notification_pretty_id: notification.pretty_id }
        expect(response).to have_http_status(:forbidden)
      end

      it "returns forbidden status for create action" do
        post :create, params: valid_params
        expect(response).to have_http_status(:forbidden)
      end

      it "returns forbidden status for edit action" do
        get :edit, params: { notification_pretty_id: notification.pretty_id, id: corrective_action.id }
        expect(response).to have_http_status(:forbidden)
      end

      it "returns forbidden status for update action" do
        patch :update, params: { notification_pretty_id: notification.pretty_id, id: corrective_action.id, corrective_action: valid_params[:corrective_action] }
        expect(response).to have_http_status(:forbidden)
      end
    end

    shared_examples "allowed access" do
      let(:success_result) { instance_double(Interactor::Context, success?: true) }

      # Centralizes form stubbing to reduce duplication and improve maintainability
      def stub_form_methods(form, additional_stubs = {})
        allow(form).to receive(:date_decided=)
        allow(form).to receive(:cache_file!).with(anything)
        allow(form).to receive_messages(additional_stubs) if additional_stubs.present?
        form
      end

      let(:form_for_create) do
        instance_double(CorrectiveActionForm, valid?: true).tap do |form|
          stub_form_methods(form, date_decided: nil, serializable_hash: {})
        end
      end

      let(:form_for_edit) do
        instance_double(CorrectiveActionForm).tap do |form|
          allow(form).to receive(:related_file=)
          allow(form).to receive(:existing_document_file_id=)
          allow(form).to receive(:load_document_file)
          allow(form).to receive(:changes_applied)
        end
      end

      let(:form_for_update) do
        instance_double(CorrectiveActionForm, valid?: true).tap do |form|
          stub_form_methods(form, {
            date_decided: nil,
            serializable_hash: {},
            action: "mandatory_recall",
            has_online_recall_information: "has_online_recall_information_no",
            online_recall_information: nil,
            legislation: ["General Product Safety Regulations 2005"],
            business_id: business.id,
            measure_type: "Mandatory",
            duration: "permanent",
            geographic_scopes: ["Great Britain"],
            details: "Test details",
            related_file: nil,
            document: nil,
            changes: nil
          })
        end
      end

      # Isolates controller authorization logic by stubbing external dependencies
      before do
        allow(CorrectiveActionForm).to receive(:new).and_return(form_for_create)
        allow(AddCorrectiveActionToNotification).to receive(:call).and_return(success_result)
        allow(CorrectiveActionForm).to receive(:from).and_return(form_for_edit)
        allow(CorrectiveActionForm).to receive(:new).and_return(form_for_update)
        allow(UpdateCorrectiveAction).to receive(:call!)
      end

      it "allows access to new action" do
        get :new, params: { notification_pretty_id: notification.pretty_id }
        expect(response).to be_successful
      end

      it "allows access to create action" do
        post :create, params: valid_params
        expect(response).to redirect_to(notification_path(notification))
      end

      it "allows access to edit action" do
        get :edit, params: { notification_pretty_id: notification.pretty_id, id: corrective_action.id }
        expect(response).to be_successful
      end

      it "allows access to update action" do
        patch :update, params: { notification_pretty_id: notification.pretty_id, id: corrective_action.id, corrective_action: valid_params[:corrective_action] }
        expect(response).to redirect_to(notification_path(notification))
      end
    end

    context "when user is the creator" do
      include_examples "allowed access"
    end

    context "when user is the owner" do
      before { sign_in(owner_user) }

      include_examples "allowed access"
    end

    context "when user is in the creator team" do
      before { sign_in(create(:user, :activated, team: creator_team)) }

      include_examples "allowed access"
    end

    context "when user is in the owner team" do
      before { sign_in(create(:user, :activated, team: owner_team)) }

      include_examples "allowed access"
    end

    context "when user is in a team with edit access" do
      before { sign_in(create(:user, :activated, team: edit_access_team)) }

      include_examples "allowed access"
    end

    context "when user is in a team with read-only access" do
      before { sign_in(create(:user, :activated, team: read_only_team)) }

      include_examples "forbidden access"
    end

    context "when user has no access" do
      before { sign_in(other_user) }

      include_examples "forbidden access"
    end
  end
end
