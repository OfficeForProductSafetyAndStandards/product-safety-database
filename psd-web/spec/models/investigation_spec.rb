require "rails_helper"

RSpec.describe Investigation, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_notify do
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
    context "when there is just a team that is the case owner" do
      let(:team) { create(:team) }
      let(:investigation) { create(:allegation, owner: team) }

      it "is a list of just the team" do
        expect(investigation.teams_with_access).to eql([team])
      end
    end

    context "when there is a team as the case owner and a collaborator team added" do
      let(:team) { create(:team) }
      let(:collaborator_team) { create(:team) }
      let(:investigation) do
        create(
          :allegation,
          owner: team,
          edit_access_collaborations: [
            create(:collaboration_edit_access, collaborator: collaborator_team)
          ]
        )
      end

      it "is a list of the team and the collaborator team" do
        expect(investigation.teams_with_access).to match_array([team, collaborator_team])
      end
    end
  end

  describe "#owner_team" do
    context "when there is a team as the case owner" do
      let(:team) { create(:team) }
      let(:investigation) { create(:allegation, owner: team) }

      it "is is the team" do
        expect(investigation.owner_team).to eql(team)
      end
    end

    context "when there is a user who belongs to a team that is the case owner" do
      let(:team) { create(:team) }
      let(:user) { create(:user, team: team) }
      let(:investigation) { create(:allegation, owner: user) }

      it "is is the team the user belongs to" do
        expect(investigation.owner_team).to eql(team)
      end
    end
  end

  describe "ownership" do
    let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
    let(:investigation) { create(:investigation, creator: user) }

    context "when owner is User" do
      it "has team owner too" do
        expect(investigation.owner_team).to eq(user.team)
      end
    end

    context "when owner is Team" do
      before do
        investigation.owner = user.team
      end

      it "does not have owner_user" do
        expect(investigation.owner_user).to eq(nil)
      end
    end

    it "is invalid without owner_team" do
      investigation.owner_team = nil
      expect(investigation).to be_invalid
    end
  end
end
