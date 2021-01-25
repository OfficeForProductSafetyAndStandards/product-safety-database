require "rails_helper"

RSpec.describe CorrectiveAction, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:corrective_action) do
    build(
      :corrective_action,
      action: action,
      other_action: other_action,
      date_decided_day: date_decided ? date_decided.day : nil,
      date_decided_month: date_decided ? date_decided.month : nil,
      date_decided_year: date_decided ? date_decided.year : nil,
      legislation: legislation,
      measure_type: measure_type,
      duration: duration,
      geographic_scope: geographic_scope,
      details: details,
      related_file: related_file,
      investigation: investigation,
      product: create(:product)
    )
  end

  let(:action) { (described_class.actions.values - %w[Other]).sample }
  let(:other_action) { nil }
  let(:date_decided) { Faker::Date.backward(days: 14) }
  let(:legislation) { Rails.application.config.legislation_constants["legislation"].sample }
  let(:measure_type) { CorrectiveAction::MEASURE_TYPES.sample }
  let(:duration) { CorrectiveAction::DURATION_TYPES.sample }
  let(:geographic_scope) { Rails.application.config.corrective_action_constants["geographic_scope"].sample }
  let(:geographic_scopes) { [geographic_scope] }
  let(:details) { Faker::Lorem.sentence }
  let(:related_file) { false }
  let(:investigation) { build(:allegation) }

  describe "#valid?" do
    describe "#geographic_scopes" do
      context "with a valid geographic scope" do
        it { is_expected.to be_valid }
      end
    end

    context "with valid input" do
      it "returns true" do
        expect(corrective_action).to be_valid
      end
    end

    context "with blank action" do
      let(:action) { nil }

      it "returns false" do
        expect(corrective_action).not_to be_valid
      end
    end

    context "when action is not 'other' and other_action is not blank" do
      let(:other_action) { Faker::Lorem.characters(number: 10_000) }

      it "is not valid with an error message for the other_action field", :aggregate_failures do
        expect(corrective_action).to be_invalid
        expect(corrective_action.errors.full_messages_for(:other_action)).to eq(["Other action must be blank"])
      end
    end

    context "when choosing other" do
      let(:action) { "other" }

      context "with blank other_action" do
        it { is_expected.to be_invalid }
      end

      context "with other_action longer than 10,000 characters" do
        let(:other_action) { Faker::Lorem.characters(number: 10_001) }

        it "returns false" do
          expect(corrective_action).not_to be_valid
        end
      end
    end

    context "with details longer than 50,000 characters" do
      let(:details) { Faker::Lorem.characters(number: 50_001) }

      it "returns false" do
        expect(corrective_action).not_to be_valid
      end
    end

    context "with future date_decided" do
      let(:date_decided) { Faker::Date.forward(days: 14) }

      it "returns false" do
        expect(corrective_action).not_to be_valid
      end
    end

    context "with blank date_decided" do
      let(:date_decided) { nil }

      it "returns false" do
        expect(corrective_action).not_to be_valid
      end
    end

    context "with blank measure_type" do
      let(:measure_type) { nil }

      it "returns false" do
        expect(corrective_action).not_to be_valid
      end
    end

    context "with invalid measure_type" do
      let(:measure_type) { "test" }

      it "returns false" do
        expect(corrective_action).not_to be_valid
      end
    end

    context "with blank duration" do
      let(:duration) { nil }

      it "returns false" do
        expect(corrective_action).not_to be_valid
      end
    end

    context "with invalid duration" do
      let(:duration) { "test" }

      it "returns false" do
        expect(corrective_action).not_to be_valid
      end
    end

    context "with blank geographic_scope" do
      let(:geographic_scope) { nil }

      it "returns false" do
        expect(corrective_action).not_to be_valid
      end
    end

    context "with invalid geographic_scope" do
      let(:geographic_scope) { "test" }

      it "returns false" do
        expect(corrective_action).not_to be_valid
      end
    end

    context "with related_file" do
      let(:related_file) { "Yes" }

      context "without an attached file" do
        it "returns false" do
          expect(corrective_action).not_to be_valid
        end
      end

      context "with an attached file" do
        let(:file) { Rails.root + "test/fixtures/files/old_risk_assessment.txt" }

        before { corrective_action.documents.attach(io: File.open(file), filename: "test.txt") }

        it "returns true" do
          expect(corrective_action).to be_valid
        end
      end
    end
  end

  describe "#create_audit_activity", :with_stubbed_mailer do
    # The audit activity requires pretty_id to be set on the Investigation
    let(:investigation) { create(:allegation) }

    it "creates an activity" do
      expect { corrective_action.save }.to change { AuditActivity::CorrectiveAction::Add.count }.by(1)
    end
  end
end
