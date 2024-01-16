RSpec.describe "Inviting users to your team", :with_stubbed_mailer, :with_stubbed_notify, type: :request do
  let(:team) { create(:team) }
  let(:user) { create(:user, :team_admin, :activated, has_viewed_introduction: true, team: user_team) }
  let(:user_team) { team }
  let(:invite_double) { instance_double(InviteUserToTeam, user: instance_double(User, email: "test@example.com")) }

  before { sign_in(user) }

  describe "#new" do
    before { get new_team_invitation_path(team) }

    it "requires secondary authentication", :with_2fa do
      expect(response).to redirect_to(new_secondary_authentication_path)
    end

    context "when the user is not a team admin" do
      let(:user) { create(:user, :activated, has_viewed_introduction: true, team: user_team) }

      it "shows an error message" do
        expect(response).to render_template("errors/forbidden")
      end
    end

    context "when the user is a member of another team" do
      let(:user_team) { create(:team) }

      it "shows an error message" do
        expect(response).to render_template("errors/forbidden")
      end
    end
  end

  describe "#create" do
    let(:params) { { invite_user_to_team_form: { email: } } }
    let(:email) { Faker::Internet.email }
    let(:form_errors_double) { instance_double(ActiveModel::Errors).as_null_object }

    it "requires secondary authentication", :with_2fa do
      post(team_invitations_path(team), params:)
      expect(response).to redirect_to(new_secondary_authentication_path)
    end

    context "when the user is not a team admin" do
      let(:user) { create(:user, :activated, has_viewed_introduction: true, team: user_team) }

      it "shows an error message" do
        post(team_invitations_path(team), params:)
        expect(response).to render_template("errors/forbidden")
      end
    end

    context "when the user is a member of another team" do
      let(:user_team) { create(:team) }

      it "shows an error message" do
        post(team_invitations_path(team), params:)
        expect(response).to render_template("errors/forbidden")
      end
    end

    context "when the form is invalid" do
      let(:email) { nil }

      before { post team_invitations_path(team), params: }

      it "returns 403 status" do
        expect(response).to have_http_status(:bad_request)
      end

      it "renders the :new template" do
        expect(response).to render_template(:new)
      end
    end

    context "when the form is valid" do
      let(:form_double) { instance_double(InviteUserToTeamForm, valid?: true, errors: form_errors_double).as_null_object }

      before do
        allow(InviteUserToTeamForm).to receive(:new).and_return(form_double)
        allow(InviteUserToTeam).to receive(:call).and_return(invite_double)
        post team_invitations_path(team), params:
      end

      it "calls the InviteUserToTeam service" do
        expect(InviteUserToTeam).to have_received(:call).with(
          hash_including({ email:, team:, inviting_user: user })
        )
      end

      it "redirects to the team page" do
        expect(response).to redirect_to(team_path(team))
      end

      it "sets the flash message" do
        expect(flash[:success]).to eq(I18n.t("invite_user_to_team.invite_sent", email: "test@example.com"))
      end
    end
  end

  describe "#resend" do
    let(:existing_user) { create(:user, :inactive, team: existing_user_team) }
    let(:existing_user_team) { user_team }

    it "requires secondary authentication", :with_2fa do
      put resend_team_invitation_path(team, existing_user)
      expect(response).to redirect_to(new_secondary_authentication_path)
    end

    context "when the user is not a team admin" do
      let(:user) { create(:user, :activated, has_viewed_introduction: true, team: user_team) }

      it "shows an error message" do
        put resend_team_invitation_path(team, existing_user)
        expect(response).to be_forbidden
      end
    end

    context "when the user is a member of another team" do
      let(:user_team) { create(:team) }
      let(:existing_user_team) { team }

      it "shows an error message" do
        put resend_team_invitation_path(team, existing_user)
        expect(response).to be_forbidden
      end
    end

    context "when the existing user is a member of another team" do
      let(:existing_user_team) { create(:team) }

      it "shows an error message" do
        put resend_team_invitation_path(team, existing_user)
        expect(response).to be_not_found
      end
    end

    context "when the existing user is on the same team" do
      before do
        allow(InviteUserToTeam).to receive(:call).and_return(invite_double)
        put resend_team_invitation_path(team, existing_user)
      end

      it "calls the InviteUserToTeam service" do
        expect(InviteUserToTeam).to have_received(:call).with({ user: existing_user, team:, inviting_user: user })
      end

      it "redirects to the team page" do
        expect(response).to redirect_to(team_path(team))
      end

      it "sets the flash message" do
        expect(flash[:success]).to eq(I18n.t("invite_user_to_team.invite_sent", email: "test@example.com"))
      end
    end
  end
end
