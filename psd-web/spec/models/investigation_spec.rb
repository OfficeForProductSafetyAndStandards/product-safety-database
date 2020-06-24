require "rails_helper"

RSpec.describe Investigation, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_notify do
  subject(:investigation) { create(:allegation) }

  describe "#build_owner_collaborations_from" do
    subject(:investigation) { Investigation::Allegation.new.build_owner_collaborations_from(user) }

    let(:user) { create(:user) }

    it "builds the relevant associations and returns self", :aggregate_failures do
      expect(investigation.owner_user_collaboration.collaborator).to be user
      expect(investigation.owner_team_collaboration.collaborator).to be user.team
    end
  end

  describe "supporting information" do
    let(:user)                                    { create(:user, :activated, has_viewed_introduction: true) }
    let(:investigation)                           { create(:allegation, owner: user.team) }
    let(:generic_supporting_information_filename) { "a generic supporting information" }
    let(:generic_image_filename)                  { "a generic image" }
    let(:image) { Rails.root.join("test/fixtures/files/testImage.png") }

    include_context "with all types of supporting information"

    before do
      investigation.documents.attach(io: StringIO.new, filename: generic_supporting_information_filename)
      investigation.documents.attach(io: File.open(image), filename: generic_image_filename, content_type: "image/png")
      investigation.save!
    end

    describe "#generic_supporting_information_attachments" do
      it "returns attachments that are not images nor attached to any type of correspondences, test result or corrective action", :aggregate_failures do
        expect(investigation.generic_supporting_information_attachments)
          .not_to include(corrective_action, email, phone_call, meeting, test_request, test_result)

        expect(investigation.generic_supporting_information_attachments.detect { |document| document.filename == generic_supporting_information_filename })
          .to be_present
        expect(investigation.generic_supporting_information_attachments.detect { |document| document.filename == generic_image_filename })
          .not_to be_present
      end
    end
  end

  describe "#teams_with_access" do
    let(:owner)  { investigation.team }
    let(:user)   { create(:user, team: owner) }
    let(:team_a) { create(:team, name: "a team") }
    let(:team_b) { create(:team, name: "b team") }

    before do
      owner.update!(name: "z to ensure the sorting is correct")
      [team_a, team_b].each do |team|
        AddTeamToAnInvestigation.call(current_user: user, investigation: investigation, collaborator_id: team.id, include_message: false)
      end
    end

    it "owner team is always the first" do
      expect(investigation.teams_with_access).to eq([owner, team_a, team_b])
    end
  end

  describe "#owner_team" do
    context "when there is a team as the case owner" do
      let(:team) { create(:team) }
      let(:investigation) { create(:allegation, owner: team) }

      it "is is the team" do
        expect(investigation.team).to eql(team)
      end
    end

    context "when there is a user who belongs to a team that is the case owner" do
      let(:team) { create(:team) }
      let(:user) { create(:user, team: team) }
      let(:investigation) { create(:allegation, owner: user) }

      it "is is the team the user belongs to" do
        expect(investigation.team).to eql(team)
      end
    end
  end

  describe "ownership" do
    let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
    let(:investigation) { create(:project, owner: user) }

    context "when owner is User" do
      it "has team owner too" do
        expect(investigation.team).to eq(user.team)
      end
    end

    it "is invalid without owner team collaboration" do
      investigation.owner_team_collaboration = nil
      expect(investigation).to be_invalid
    end
  end
end
