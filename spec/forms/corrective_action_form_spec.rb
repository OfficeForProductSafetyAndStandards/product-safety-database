require "rails_helper"

RSpec.describe CorrectiveActionForm, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  include ActionDispatch::TestProcess::FixtureFile
  subject(:corrective_action_form) do
    described_class.new(
      action: action,
      other_action: other_action,
      date_decided: date_decided,
      legislation: legislation,
      measure_type: measure_type,
      duration: duration,
      geographic_scope: geographic_scope,
      details: details,
      related_file: related_file,
      product_id: create(:product).id,
      business_id: create(:business).id,
      file: file_form
    )
  end

  let(:file) { fixture_file_upload(file_fixture("files/corrective_action.txt")) }
  let(:file_description) { Faker::Hipster.sentence }
  let(:file_form) { { file: file, description: file_description } }
  let(:action) { (CorrectiveAction.actions.keys - %w[other]).sample }
  let(:other_action) { nil }
  let(:date_decided) { Faker::Date.backward(days: 14) }
  let(:legislation) { Rails.application.config.legislation_constants["legislation"].sample }
  let(:measure_type) { CorrectiveAction::MEASURE_TYPES.sample }
  let(:duration) { CorrectiveAction::DURATION_TYPES.sample }
  let(:geographic_scope) { Rails.application.config.corrective_action_constants["geographic_scope"].sample }
  let(:details) { Faker::Lorem.sentence }
  let(:related_file) { false }
  let(:investigation) { build(:allegation) }

  describe "#valid?" do
    context "with valid input" do
      it "returns true" do
        expect(corrective_action_form).to be_valid
      end
    end

    context "with blank action" do
      let(:action) { nil }

      it "returns false" do
        expect(corrective_action_form).not_to be_valid
      end
    end

    context "when action is not 'other' and other_action is not blank" do
      let(:other_action) { Faker::Lorem.characters(number: 10_000) }

      it "is not valid with an error message for the other_action field", :aggregate_failures do
        expect(corrective_action_form).to be_invalid
        expect(corrective_action_form.errors.full_messages_for(:other_action)).to eq(["Other action must be blank"])
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
          expect(corrective_action_form).not_to be_valid
        end
      end
    end

    context "with details longer than 50,000 characters" do
      let(:details) { Faker::Lorem.characters(number: 50_001) }

      it "returns false" do
        expect(corrective_action_form).not_to be_valid
      end
    end

    context "with future date_decided" do
      let(:date_decided) { Faker::Date.forward(days: 14) }

      it "returns false" do
        expect(corrective_action_form).not_to be_valid
      end
    end

    context "with blank date_decided" do
      let(:date_decided) { nil }

      it "returns false" do
        expect(corrective_action_form).not_to be_valid
      end
    end

    context "with blank measure_type" do
      let(:measure_type) { nil }

      it "returns false" do
        expect(corrective_action_form).not_to be_valid
      end
    end

    context "with invalid measure_type" do
      let(:measure_type) { "test" }

      it "returns false" do
        expect(corrective_action_form).not_to be_valid
      end
    end

    context "with blank duration" do
      let(:duration) { nil }

      it "returns false" do
        expect(corrective_action_form).not_to be_valid
      end
    end

    context "with invalid duration" do
      let(:duration) { "test" }

      it "returns false" do
        expect(corrective_action_form).not_to be_valid
      end
    end

    context "with blank geographic_scope" do
      let(:geographic_scope) { nil }

      it "returns false" do
        expect(corrective_action_form).not_to be_valid
      end
    end

    context "with invalid geographic_scope" do
      let(:geographic_scope) { "test" }

      it "returns false" do
        expect(corrective_action_form).not_to be_valid
      end
    end

    context "with related_file" do
      let(:related_file) { "Yes" }

      context "without an attached file" do
        let(:file_form) { nil }

        it "returns false" do
          expect(corrective_action_form).not_to be_valid
        end
      end

      context "with an attached file" do
        it "returns true" do
          expect(corrective_action_form).to be_valid
        end
      end
    end
  end
end
