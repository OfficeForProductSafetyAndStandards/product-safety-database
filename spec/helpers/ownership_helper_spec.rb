RSpec.describe OwnershipHelper do
  describe "#add_your_team_values", :with_stubbed_mailer do
    let(:user)           { create(:user) }
    let(:another_user)   { create(:user) }
    let!(:investigation) { create(:allegation, creator: user) }

    before do
      allow(helper).to receive(:current_user) { user }
    end

    context "when investigation owner is current user" do
      it "returns expected items" do
        expect(helper.add_your_team_values([], investigation, "")).to eq([
          { divider: "Your team" },
          { text: investigation.owner.decorate.display_name(viewer: helper.current_user), value: investigation.owner.id, checked: true },
          { text: "Someone else in your team", value: "someone_else_in_your_team", conditional: { html: "" } },
          { text: helper.current_user.team.decorate.display_name(viewer: helper.current_user), value: helper.current_user.team.id, checked: false }
        ])
      end
    end

    context "when investigation owner is current user's team" do
      before do
        allow(investigation).to receive(:owner) { helper.current_user.team }
      end

      it "returns expected items" do
        expect(helper.add_your_team_values([], investigation, "")).to eq([
          { divider: "Your team" },
          { text: investigation.owner.decorate.display_name(viewer: helper.current_user), value: investigation.owner.id, checked: true },
          { text: helper.current_user.decorate.display_name(viewer: helper.current_user), value: helper.current_user.id, checked: false },
          { text: "Someone else in your team", value: "someone_else_in_your_team", conditional: { html: "" } }
        ])
      end
    end

    context "when investigation owner is neither current user nor current user`s team" do
      before do
        allow(investigation).to receive(:owner) { another_user }
      end

      it "returns expected items" do
        expect(helper.add_your_team_values([], investigation, "")).to eq([
          { divider: "Your team" },
          { text: investigation.owner.decorate.display_name(viewer: helper.current_user), value: investigation.owner.id, checked: true },
          { text: helper.current_user.decorate.display_name(viewer: helper.current_user), value: helper.current_user.id, checked: false },
          { text: "Someone else in your team", value: "someone_else_in_your_team", conditional: { html: "" } },
          { text: helper.current_user.team.decorate.display_name(viewer: helper.current_user), value: helper.current_user.team.id, checked: false }
        ])
      end
    end
  end

  describe "#opss_hint_text", :with_stubbed_mailer do
    let(:opss_user)                { create(:user, :opss_user) }
    let(:other_user)               { create(:user) }
    let(:incident_management_team) { create(:team, name: "OPSS Incident Management") }
    let(:other_team)               { create(:team) }

    it "returns hint text if current user is not opss and team is the incident management team" do
      allow(helper).to receive(:current_user) { other_user }
      expect(helper.opss_hint_text(incident_management_team)).to eq "For reporting serious risks to OPSS"
    end

    it "returns nil if current user is opss" do
      allow(helper).to receive(:current_user) { opss_user }
      expect(helper.opss_hint_text(incident_management_team)).to eq nil
    end

    it "returns nil if team is not the incident management team" do
      allow(helper).to receive(:current_user) { other_user }
      expect(helper.opss_hint_text(other_team)).to eq nil
    end
  end
end
