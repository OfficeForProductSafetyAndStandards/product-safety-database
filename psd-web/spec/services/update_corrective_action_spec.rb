require "rails_helper"

RSpec.describe UpdateCorrectiveAction, :with_stubbed_mailer, :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_test_queue_adapter do
  include ActionDispatch::TestProcess::FixtureFile

  subject(:update_corrective_action) do
    described_class.call(
      corrective_action: corrective_action,
      user: user,
      corrective_action_params: corrective_action_params
    )
  end

  let(:user)             { create(:user) }
  let(:investigation)    { create(:allegation, creator: user) }
  let(:product)          { create(:product) }
  let(:business)         { create(:business) }
  let(:old_date_decided) { Time.zone.today }
  let(:corrective_action) do
    create(
      :corrective_action,
      :with_file,
      investigation: investigation,
      date_decided: old_date_decided,
      product: product,
      business: business
    )
  end
  let(:new_date_decided) { (old_date_decided - 1.day).to_date }
  let(:new_file_description) { "new corrective action file description" }
  let(:corrective_action_params) do
    ActionController::Parameters.new(
      date_decided: { year: new_date_decided.year, month: new_date_decided.month, day: new_date_decided.day },
      file: {
        file: fixture_file_upload(file_fixture("corrective_action.txt")),
        description: new_file_description
      }
    ).permit!
  end

  describe "#call" do
    context "with no parameters" do
      it "returns a failure" do
        expect(described_class.call).to be_failure
      end
    end

    context "when missing parameters" do
      let(:params) do
        {
          corrective_action: corrective_action,
          user: user,
          corrective_action_params: {}
        }
      end

      it { expect(described_class.call(params.except(:corrective_action))).to be_a_failure }
      it { expect(described_class.call(params.except(:corrective_action_params))).to be_a_failure }
      it { expect(described_class.call(params.except(:user))).to be_a_failure }
    end

    context "with required parameters that trigger a validation error" do
      before do
        corrective_action_params[:date_decided][:day] = ""
      end

      it "returns a failure", :aggregate_failures do
        expect(update_corrective_action).to be_a_failure
        expect(corrective_action.errors.full_messages_for(:date_decided)).to eq(["Enter date the corrective action was decided and include a day"])
      end
    end

    context "with the required parameters" do

      context "when no changes have been made" do
        let(:corrective_action_params) {
          ActionController::Parameters.new(
            summary: corrective_action.summary,
            date_decided_day: corrective_action.date_decided.day,
            date_decided_month: corrective_action.date_decided.month,
            date_decided_year: corrective_action.date_decided.year,
            legislation: corrective_action.legislation,
            duration: corrective_action.duration,
            details: corrective_action.details,
            measure_type: corrective_action.measure_type,
            geographic_scope: corrective_action.geographic_scope,
            file: { description: corrective_action.documents.first.metadata[:description] }
          ).permit!
        }

        it "does not change corrective action" do
          expect { update_corrective_action }.not_to change(corrective_action, :attributes)
        end

        it "does not change the attached document" do
          expect { update_corrective_action }.not_to change(corrective_action.documents, :first)
        end

        it "does not change the attached document's metadata" do
          expect { update_corrective_action }.not_to change(corrective_action.documents.first, :metadata)
        end

        it "does not create an audit log" do
          expect { update_corrective_action }.not_to change(corrective_action.investigation.activities, :count)
        end
      end

      it "updates the corrective action" do
        expect {
          update_corrective_action
        }.to change(corrective_action, :date_decided).from(old_date_decided).to(new_date_decided)
      end

      context "with a new file" do
        it "stored the new file with the description", :aggregate_failures do
          update_corrective_action

          document = corrective_action.documents.first
          expect(document.filename.to_s).to eq("corrective_action.txt")
          expect(document.metadata[:description]).to eq(new_file_description)
        end
      end

      context "without a new file" do
        before do
          corrective_action_params[:file][:file] = nil
        end

        it "stored the new file with the description", :aggregate_failures do
          expect {
            update_corrective_action
          }.not_to change(corrective_action, :documents)
        end
      end

      it "generates an activity entry with the changes" do
        update_corrective_action

        activity_timeline_entry = investigation.activities.reload.order(:created_at).find_by!(type: "AuditActivity::CorrectiveAction::Update")
        expect(activity_timeline_entry).to have_attributes({})
      end
    end
  end
end
