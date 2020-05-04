require "rails_helper"

RSpec.describe TeamDecorator do
  subject(:decorated_team) { team.decorate }

  let(:team) { build_stubbed(:team) }

  describe "#assignee_short_name" do
    it { expect(decorated_team.assignee_short_name).to eq(team.display_name) }
  end

  describe "#display_name" do
    let(:team) { create(:team, organisation_id: organisation.id) }

    let(:organisation) { create(:organisation) }

    let(:user_same_org) { create(:user, organisation: organisation) }
    let(:user_other_org) { create(:user) }

    let(:ignore_visibility_restrictions) { false }
    let(:result) do
      decorated_team.display_name(ignore_visibility_restrictions: ignore_visibility_restrictions, current_user: viewing_user)
    end

    context "with user of same organisation" do
      let(:viewing_user) { user_same_org }

      it "returns the team name" do
        expect(result).to eq(team.name)
      end
    end

    context "with user of another organisation" do
      let(:viewing_user) { user_other_org }

      context "with ignore_visibility_restrictions: true" do
        let(:ignore_visibility_restrictions) { true }

        it "returns the team name" do
          expect(result).to eq(team.name)
        end
      end

      context "with ignore_visibility_restrictions: false" do
        it "returns the organisation name" do
          expect(result).to eq(organisation.name)
        end
      end
    end
  end
end
