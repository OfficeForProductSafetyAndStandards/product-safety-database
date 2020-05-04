require "rails_helper"

RSpec.describe UserDecorator do
  subject(:decorated_user) { user.decorate }

  let(:user) { build(:user) }

  describe "#owner_short_name" do
    let(:viewing_user) { build(:user, organisation: organisation) }

    context "when viewing from a user within the same organisation" do
      let(:organisation) { user.organisation }

      it { expect(decorated_user.owner_short_name(viewing_user: viewing_user)).to eq(user.name) }
    end

    context "when viewing from a user within another organisation" do
      let(:organisation) { build(:organisation) }

      it { expect(decorated_user.owner_short_name(viewing_user: viewing_user)).to eq(user.organisation.name) }
    end
  end

  describe "#full_name" do
    context "when the user is deleted" do
      let(:user) { build_stubbed(:user, :deleted, name: "Foo Bar") }

      it "returns user name with a tag after their name" do
        expect(decorated_user.full_name).to eq("Foo Bar [user deleted]")
      end
    end

    it "non deleted users show their name" do
      expect(decorated_user.full_name).to eq(user.name)
    end
  end

  describe "#display_name" do
    let(:organisation_name) { "test org" }
    let(:other_organisation_name) { "other org" }
    let(:organisation) { create(:organisation, name: organisation_name) }
    let(:other_organisation) { create(:organisation, name: other_organisation_name) }

    let(:team_name) { "test team" }
    let(:other_org_team_name) { "other org team" }
    let(:team) { create(:team, name: team_name, organisation: organisation) }
    let(:other_organisation_team) { create(:team, name: other_org_team_name, organisation: other_organisation) }

    let(:user_name) { "test user" }
    let(:other_user_name) { "other user" }
    let(:user_organisation) { organisation }
    let(:user_deleted_timestamp) { nil }
    let(:user) { create(:user, name: user_name, organisation: user_organisation, teams: [team], deleted_at: user_deleted_timestamp) }
    let(:other_user) { create(:user, name: other_user_name, organisation: organisation) }

    let(:ignore_visibility_restrictions) { false }

    let(:result) { decorated_user.display_name(other_user: other_user, ignore_visibility_restrictions: ignore_visibility_restrictions) }

    context "when the user is a member of the same organisation" do
      it "returns their name and team names" do
        expect(result).to eq("#{user_name} (#{team_name})")
      end

      context "when the user is deleted" do
        let(:user_deleted_timestamp) { Time.current }

        it "gets a 'user deleted' flag" do
          expect(result).to eq("#{user_name} (#{team_name}) [user deleted]")
        end
      end
    end

    context "when the user is a member of a different organisation" do
      let(:user_organisation) { other_organisation }
      let(:team) { other_organisation_team }

      context "with ignore_visibility_restrictions: false" do
        it "returns their name and organisation name" do
          expect(result).to eq("#{user_name} (#{other_organisation_name})")
        end

        context "when the user is deleted" do
          let(:user_deleted_timestamp) { Time.current }

          it "gets a 'user deleted' flag" do
            expect(result).to eq("#{user_name} (#{other_organisation_name}) [user deleted]")
          end
        end
      end

      context "with ignore_visibility_restrictions: true" do
        let(:ignore_visibility_restrictions) { true }

        it "returns their name and team names" do
          expect(result).to eq("#{user_name} (#{other_org_team_name})")
        end

        context "when the user is deleted" do
          let(:user_deleted_timestamp) { Time.current }

          it "gets a 'user deleted' flag" do
            expect(result).to eq("#{user_name} (#{other_org_team_name}) [user deleted]")
          end
        end
      end
    end

    context "with other_user: nil" do
      let(:other_user) { nil }

      it "returns their name and organisation name" do
        expect(result).to eq("#{user_name} (#{organisation_name})")
      end

      context "when the user is deleted" do
        let(:user_deleted_timestamp) { Time.current }

        it "gets a 'user deleted' flag" do
          expect(result).to eq("#{user_name} (#{organisation_name}) [user deleted]")
        end
      end
    end
  end
end
