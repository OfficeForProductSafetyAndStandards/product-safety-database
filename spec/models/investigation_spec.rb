RSpec.describe Investigation, :with_stubbed_mailer, :with_stubbed_notify, :with_stubbed_opensearch do
  subject(:investigation) { create(:allegation) }

  describe "#build_owner_collaborations_from", :with_stubbed_opensearch do
    subject(:investigation) { Investigation::Allegation.new.build_owner_collaborations_from(user) }

    let(:user) { create(:user) }

    it "builds the relevant associations and returns self", :aggregate_failures do
      expect(investigation.owner_user_collaboration.collaborator).to be user
      expect(investigation.owner_team_collaboration.collaborator).to be user.team
    end
  end

  describe "supporting information" do
    let(:user)                                    { create(:user, :activated, has_viewed_introduction: true) }
    let(:investigation)                           { create(:allegation, creator: user) }
    let(:generic_supporting_information_filename) { "a generic supporting information" }
    let(:generic_image_filename)                  { "a generic image" }
    let(:image) { Rails.root.join("test/fixtures/files/testImage.png") }

    include_context "with all types of supporting information"

    before do
      ChangeNotificationOwner.call!(notification: investigation, owner: user.team, user:)
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
    let(:owner)  { investigation.owner_team }
    let(:user)   { create(:user, team: owner) }
    let(:team_a) { create(:team, name: "a team") }
    let(:team_b) { create(:team, name: "b team") }

    before do
      owner.update!(name: "z to ensure the sorting is correct")
      [team_a, team_b].each do |team|
        AddTeamToNotification.call(user:, notification: investigation, team:, collaboration_class: Collaboration::Access::Edit)
      end
    end

    it "owner team is always the first" do
      expect(investigation.teams_with_access).to eq([owner, team_a, team_b])
    end
  end

  describe "#risk_level_currently_validated?" do
    it "returns true if risk_validated_by is not nil" do
      investigation.update!(risk_validated_by: "Anyone")
      expect(investigation).to be_risk_level_currently_validated
    end

    it "returns false if risk_validated_by is nil" do
      expect(investigation).not_to be_risk_level_currently_validated
    end
  end

  describe "#owner_team" do
    context "when there is a team as the case owner" do
      let(:team) { create(:team) }
      let(:investigation) { create(:allegation, creator: create(:user, team:)) }

      it "is is the team" do
        expect(investigation.owner_team).to eq(team)
      end
    end

    context "when there is a user who belongs to a team that is the case owner" do
      let(:team) { create(:team) }
      let(:user) { create(:user, team:) }
      let(:investigation) { create(:allegation, creator: user) }

      before do
        ChangeNotificationOwner.call!(notification: investigation, user:, owner: team)
      end

      it "is is the team the user belongs to" do
        expect(investigation.owner_team).to eq(team)
      end
    end
  end

  describe "ownership" do
    let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
    let(:investigation) { create(:project, creator: user) }

    context "when owner is User" do
      it "has team owner too" do
        expect(investigation.owner_team).to eq(user.team)
      end
    end

    it "is invalid without owner team collaboration" do
      investigation.owner_team_collaboration = nil
      expect(investigation).to be_invalid
    end
  end

  describe "#categories" do
    let(:product_category) { Faker::Hipster.unique.word }

    before do
      investigation.product_category = product_category
    end

    context "when no products" do
      specify { expect(investigation.categories).to eq([product_category]) }
    end

    context "with products" do
      let(:product_one) { create(:product, category: Faker::Hipster.unique.word) }
      let(:product_two) { create(:product, category: Faker::Hipster.unique.word) }

      before do
        investigation.products << product_one << product_two
      end

      specify { expect(investigation.categories).to eq([product_category, product_one.category, product_two.category]) }

      context "when a product does not have a category" do
        before { product_one.category = nil }

        specify { expect(investigation.categories).to eq([product_category, product_two.category]) }
      end

      context "when a products have the same category" do
        before do
          product_one.category = product_two.category
        end

        specify { expect(investigation.categories).to eq([product_category, product_two.category]) }
      end
    end
  end

  describe "#non_owner_teams_with_access" do
    let(:user)             { create(:user, :activated, has_viewed_introduction: true) }
    let(:read_only_team)   { create(:team) }
    let(:edit_access_team) { create(:team) }
    let(:investigation)    { create(:allegation, creator: user, read_only_teams: [read_only_team], edit_access_teams: [edit_access_team]) }

    it "returns teams with read access or edit access but excludes the owner team" do
      expect(investigation.non_owner_teams_with_access).to match_array([read_only_team, edit_access_team])
    end
  end
end
