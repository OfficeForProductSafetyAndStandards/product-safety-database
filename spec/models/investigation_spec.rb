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
    let(:investigation)                           { create(:allegation, creator: user) }
    let(:generic_supporting_information_filename) { "a generic supporting information" }
    let(:generic_image_filename)                  { "a generic image" }
    let(:image) { Rails.root.join("test/fixtures/files/testImage.png") }

    include_context "with all types of supporting information"

    before do
      ChangeCaseOwner.call!(investigation: investigation, owner: user.team, user: user)
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
        AddTeamToCase.call(user: user, investigation: investigation, team: team, collaboration_class: Collaboration::Access::Edit)
      end
    end

    it "owner team is always the first" do
      expect(investigation.teams_with_access).to eq([owner, team_a, team_b])
    end
  end

  describe "#owner_team" do
    context "when there is a team as the case owner" do
      let(:team) { create(:team) }
      let(:investigation) { create(:allegation, creator: create(:user, team: team)) }

      it "is is the team" do
        expect(investigation.owner_team).to eq(team)
      end
    end

    context "when there is a user who belongs to a team that is the case owner" do
      let(:team) { create(:team) }
      let(:user) { create(:user, team: team) }
      let(:investigation) { create(:allegation, creator: user) }

      before do
        ChangeCaseOwner.call!(investigation: investigation, user: user, owner: team)
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

  describe "custom_risk_level validity" do
    let(:investigation) do
      build_stubbed(:allegation, custom_risk_level: custom_risk_level, risk_level: risk_level)
    end

    context "with a custom risk level" do
      let(:custom_risk_level) { "Custom level" }

      context "when the risk_level is also set" do
        let(:risk_level) { "low" }

        it "contains validation errors for the attribute" do
          investigation.validate
          expect(investigation.errors.full_messages_for(:custom_risk_level))
            .to eq ["Custom risk level must be blank when risk level is not 'other'"]
        end
      end

      context "when the risk_level is set to 'other'" do
        let(:risk_level) { "other" }

        it "does not contain validation errors for the attribute" do
          investigation.validate
          expect(investigation.errors.full_messages_for(:custom_risk_level)).to be_empty
        end
      end

      context "when the risk level is not set" do
        let(:risk_level) { nil }

        it "contains validation errors for the attribute" do
          investigation.validate
          expect(investigation.errors.full_messages_for(:custom_risk_level))
            .to eq ["Custom risk level must be blank when risk level is not 'other'"]
        end
      end
    end

    context "without a custom risk level" do
      let(:custom_risk_level) { nil }

      context "when the risk_level is set" do
        let(:risk_level) { "low" }

        it "does not contain validation errors for the attribute" do
          investigation.validate
          expect(investigation.errors.full_messages_for(:custom_risk_level)).to be_empty
        end
      end

      context "when the risk_level is set to 'other'" do
        let(:risk_level) { "other" }

        it "contains validation errors for the attribute" do
          investigation.validate
          expect(investigation.errors.full_messages_for(:custom_risk_level))
            .to eq ["Custom risk level must be present when risk level is 'other'"]
        end
      end

      context "when the risk level is not set" do
        let(:risk_level) { nil }

        it "does not contain validation errors for the attribute" do
          investigation.validate
          expect(investigation.errors.full_messages_for(:custom_risk_level)).to be_empty
        end
      end
    end
  end

  describe "#categories" do
    before do
      investigation.product_category = "Gadgets"
    end

    context "when no products" do
      specify { expect(investigation.categories).to eq(%w[Gadgets]) }
    end

    context "with products" do
      let(:product_one) { create(:product, category: "Lifts") }
      let(:product_two) { create(:product, category: "Machinery") }

      before do
        investigation.products << product_one << product_two
      end

      specify { expect(investigation.categories).to eq(%w[Gadgets Lifts Machinery]) }

      context "when a product does not have a category" do
        before { product_one.category = nil }

        specify { expect(investigation.categories).to eq(%w[Gadgets Machinery]) }
      end

      context "when a products have the same category" do
        let(:product_one) { create(:product, category: "Gadgets") }

        specify { expect(investigation.categories).to eq(%w[Gadgets Machinery]) }
      end
    end
  end
end
