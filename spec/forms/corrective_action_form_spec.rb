require "rails_helper"

RSpec.describe CorrectiveActionForm, :with_stubbed_antivirus, :with_stubbed_mailer do
  include ActionDispatch::TestProcess::FixtureFile
  subject(:corrective_action_form) do
    described_class.new(
      action:,
      other_action:,
      date_decided:,
      legislation:,
      measure_type:,
      duration:,
      geographic_scopes:,
      details:,
      related_file:,
      investigation_product_id:,
      business_id: create(:business).id,
      has_online_recall_information:,
      online_recall_information:,
      file: file_form,
      further_corrective_action:
    ).tap(&:valid?)
  end

  let(:investigation_product_id) { create(:investigation_product).id }
  let(:file) { fixture_file_upload(file_fixture("corrective_action.txt")) }
  let(:file_description) { Faker::Hipster.sentence }
  let(:file_form) { { file:, description: file_description } }
  let(:action) { (CorrectiveAction.actions.keys - %w[other]).sample }
  let(:other_action) { nil }
  let(:date_decided) { Faker::Date.backward(days: 14) }
  let(:legislation) { Rails.application.config.legislation_constants["legislation"].sample }
  let(:measure_type) { CorrectiveAction::MEASURE_TYPES.sample }
  let(:duration) { CorrectiveAction::DURATION_TYPES.sample }
  let(:geographic_scopes) { CorrectiveAction::GEOGRAPHIC_SCOPES[0..rand(CorrectiveAction::GEOGRAPHIC_SCOPES.size - 1)] }
  let(:details) { Faker::Lorem.sentence }
  let(:related_file) { false }
  let(:investigation) { build(:allegation) }
  let(:has_online_recall_information) { CorrectiveAction.has_online_recall_informations["has_online_recall_information_no"] }
  let(:online_recall_information) { nil }
  let(:further_corrective_action) { false }

  describe ".from" do
    subject(:corrective_action_form) { described_class.from(corrective_action) }

    context "without a previously attached documnet" do
      let(:corrective_action) { create(:corrective_action) }

      it { is_expected.not_to be_related_file }
    end

    context "with a previously attached documnet" do
      let(:corrective_action) { create(:corrective_action, :with_document) }

      it { is_expected.to be_related_file }
    end
  end

  describe "#valid?" do
    let(:form) { corrective_action_form }

    it_behaves_like "it does not allow malformed dates", :date_decided
    it_behaves_like "it does not allow an incomplete", :date_decided
    it_behaves_like "it does not allow far away dates", :date_decided

    context "with valid input" do
      it "returns true" do
        expect(corrective_action_form).to be_valid
      end
    end

    context "without an investigation product" do
      let(:investigation_product_id) { nil }

      context "with add_corrective_action custom context" do
        it "returns false" do
          expect(corrective_action_form).not_to be_valid(:add_corrective_action)
        end
      end

      context "with edit_corrective_action custom context" do
        it "returns false" do
          expect(corrective_action_form).not_to be_valid(:edit_corrective_action)
        end
      end

      context "with ts_flow custom context" do
        it "returns true" do
          expect(corrective_action_form).to be_valid(:ts_flow)
        end
      end

      context "with no custom context" do
        it "returns true" do
          expect(corrective_action_form).to be_valid
        end
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

      it "clears the other action", :aggregate_failures do
        expect(corrective_action_form).to be_valid
        expect(corrective_action_form.other_action).to be_nil
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

    context "with details longer than 32,767 characters" do
      let(:details) { Faker::Lorem.characters(number: 32_768) }

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
      let(:geographic_scopes) { [] }

      it "returns false" do
        expect(corrective_action_form).not_to be_valid
      end
    end

    context "with invalid geographic_scope" do
      let(:geographic_scopes) { %w[test] }

      it "returns false" do
        expect(corrective_action_form).not_to be_valid
      end
    end

    context "with related_file" do
      let(:related_file) { "Yes" }

      context "without an attached file" do
        let(:file_form) { { description: Faker::Hipster.sentence } }

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

    describe "recall information" do
      context "when has recall information has not been provided" do
        let(:has_online_recall_information) { nil }

        it "is invalid and has the correct error message", :aggregate_failures do
          expect(corrective_action_form).to be_invalid
          expect(corrective_action_form.errors.full_messages).to eq(["Select yes if the business responsible has published recall information online"])
        end
      end

      context "when has online recall information has been provided" do
        context "with no recall information" do
          let(:has_online_recall_information) { CorrectiveAction.has_online_recall_informations["has_online_recall_information_no"] }

          it { is_expected.to be_valid }
        end

        context "with recall information not relevant" do
          let(:has_online_recall_information) { CorrectiveAction.has_online_recall_informations["has_online_recall_information_not_relevant"] }

          it { is_expected.to be_valid }
        end

        context "with recall information" do
          let(:has_online_recall_information) { CorrectiveAction.has_online_recall_informations["has_online_recall_information_yes"] }

          context "when recall information is not provided" do
            it "is invalid and has the correct error message", :aggregate_failures do
              expect(corrective_action_form).to be_invalid
              expect(corrective_action_form.errors.full_messages).to eq(["Enter the webpage where the business responsible published recall information"])
            end
          end

          context "when recall information is provided" do
            let(:online_recall_information) { Faker::Hipster.sentence }

            it { is_expected.to be_valid }
          end
        end
      end
    end
  end

  describe "#initialize" do
    context "when online_recall_information is not empty" do
      let(:online_recall_information) { attributes_for(:corrective_action)[:online_recall_information] }

      context "when has_online_recall_information = has_online_recall_information_no" do
        let(:has_online_recall_information) { "has_online_recall_information_no" }

        it "clears the online_recall_information field" do
          expect(corrective_action_form.online_recall_information).to be_nil
        end
      end

      context "when has_online_recall_information = has_online_recall_information_not_relevant" do
        let(:has_online_recall_information) { "has_online_recall_information_not_relevant" }

        it "clears the online_recall_information field" do
          expect(corrective_action_form.online_recall_information).to be_nil
        end
      end

      context "when has_online_recall_information = has_online_recall_information_yes" do
        let(:has_online_recall_information) { "has_online_recall_information_yes" }

        it "clears the online_recall_information field" do
          expect(corrective_action_form.online_recall_information).to eq(online_recall_information)
        end
      end
    end
  end

  describe "#related_file" do
    context "with a previously attached document" do
      subject(:corrective_action_form) { described_class.from(corrective_action) }

      let(:corrective_action) { create(:corrective_action, :with_document) }

      before do
        corrective_action_form.assign_attributes(related_file:, file: file_form)
        corrective_action_form.valid?
      end

      context "when no related file attached" do
        let(:related_file) { "off" }
        let(:file_form) { nil }

        context "when previously had a document attached" do
          it "clear the document fields and the form changes reflects there is no more and attchment" do
            expect(corrective_action_form)
              .to have_attributes(existing_document_file_id: nil, filename: nil, file_description: nil)
          end
        end
      end

      context "when replacing the attached document" do
        let(:related_file) { "on" }
        let(:previous_existing_document_file_id) { corrective_action.document.signed_id }
        let(:previous_filename)                  { corrective_action.document.filename }
        let(:previous_file_description)          { corrective_action.document.metadata["description"] }
        let(:file)                               { fixture_file_upload(file_fixture("new_corrective_action.txt")) }
        let(:file_description)                   { Faker::Hipster.sentence }

        it "replaces saves the blob", :aggregate_failures do
          expect(ActiveStorage::Blob.find_signed!(corrective_action_form.document.signed_id))
            .to have_attributes(filename: ActiveStorage::Filename.new("new_corrective_action.txt"))

          expect(corrective_action_form.changes)
            .to include(
              existing_document_file_id: [previous_existing_document_file_id, corrective_action_form.document.signed_id],
              filename: [previous_filename, "new_corrective_action.txt"], file_description: [previous_file_description, file_description]
            )
        end
      end
    end
  end
end
