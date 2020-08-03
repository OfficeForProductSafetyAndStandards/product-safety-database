require "rails_helper"

RSpec.describe UpdateCorrectiveAction, :with_stubbed_mailer, :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_test_queue_adapter do
  include ActionDispatch::TestProcess::FixtureFile

  subject(:update_corrective_action) do
    described_class.call(
      corrective_action: corrective_action,
      corrective_action_params: corrective_action_params,
      user: user
    )
  end

  let(:user)             { create(:user) }
  let(:case_creator)     { create(:user, team: user.team) }
  let(:investigation)    { create(:allegation, creator: case_creator) }
  let(:product)          { create(:product) }
  let(:business)         { create(:business) }
  let(:old_date_decided) { Time.zone.today }
  let(:related_file)     { true }
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

  let(:corrective_action_params) do
    {
      date_decided_day: corrective_action.date_decided.day,
      date_decided_month: corrective_action.date_decided.month,
      date_decided_year: corrective_action.date_decided.year,
      related_file: "Yes",
      file: {
        description: new_file_description
      }
    }
  end
  let(:new_date_decided) { (old_date_decided - 1.day).to_date }
  let(:new_file_description) { "new corrective action file description" }
  let(:new_document) { fixture_file_upload(file_fixture("corrective_action.txt")) }

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
          previous_documents: {},
          file_description: new_file_description
        }
      end

      it { expect(described_class.call(params.except(:corrective_action))).to be_a_failure }
      it { expect(described_class.call(params.except(:user))).to be_a_failure }
    end

    context "with the required parameters" do
      context "when no changes have been made" do
        let(:new_file_description) { corrective_action.documents.first.metadata[:description] }

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

      context "when changes have been made" do
        before do
          corrective_action_params[:date_decided_day] = new_date_decided.day
          corrective_action_params[:date_decided_month] = new_date_decided.month
          corrective_action_params[:date_decided_year] = new_date_decided.year
        end

        it "updates the corrective action" do
          expect {
            update_corrective_action
          }.to change(corrective_action, :date_decided).from(old_date_decided).to(new_date_decided)
        end

        describe "notifications" do
          let(:activity)       { corrective_action.reload.investigation.activities.find_by!(type: "AuditActivity::CorrectiveAction::Update") }
          let(:body)           { "#{activity.source.show(user)} edited a corrective action on the #{investigation.case_type}." }
          let(:email_subject)  { "Corrective action edited for #{investigation.case_type.upcase_first}" }
          let(:mailer)         { double(deliver_later: nil) } # rubocop:disable RSpec/VerifiedDoubles

          it "notifies the owner team" do
            allow(NotifyMailer).to receive(:investigation_updated).and_return(mailer)

            update_corrective_action

            expect(NotifyMailer)
              .to have_received(:investigation_updated)
                    .with(investigation.pretty_id, case_creator.name, case_creator.email, body, email_subject)
          end

          context "when removing the previously attached file" do
            before { corrective_action_params[:related_file] = "off" }

            it "removes the related file" do
              expect { update_corrective_action }
                .to change(corrective_action.reload.documents, :any?).from(true).to(false)
            end
          end
        end
      end
    end

    context "with no changes" do
      before { corrective_action.documents.detach }

      let(:corrective_action_params) do
        ActionController::Parameters.new(
          date_decided: {
            day: corrective_action.date_decided.day,
            month: corrective_action.date_decided.month,
            year: corrective_action.date_decided.year,
          },
          summary: corrective_action.summary,
          legislation: corrective_action.legislation,
          duration: corrective_action.duration,
          details: corrective_action.details,
          measure_type: corrective_action.measure_type,
          related_file: corrective_action.related_file,
          file: { description: "" }
        ).permit!
      end

      it "does not create an audit activity" do
        expect { update_corrective_action }.not_to change(corrective_action.investigation.activities, :count)
      end
    end

    context "with no previously attached file" do
      let(:corrective_action) do
        create(
          :corrective_action,
          investigation: investigation,
          date_decided: old_date_decided,
          product: product,
          business: business
        )
      end

      let(:corrective_action_params) do
        ActionController::Parameters.new(
          date_decided: {
            day: corrective_action.date_decided.day,
            month: corrective_action.date_decided.month,
            year: corrective_action.date_decided.year,
          },
          summary: corrective_action.summary,
          legislation: corrective_action.legislation,
          duration: corrective_action.duration,
          details: corrective_action.details,
          measure_type: corrective_action.measure_type,
          related_file: corrective_action.related_file,
          file: {
            file: fixture_file_upload(file_fixture("corrective_action.txt")),
            description: new_file_description
          }
        ).permit!
      end

      it "stored the new file with the description", :aggregate_failures do
        update_corrective_action

        document = corrective_action.reload.documents.first
        expect(document.filename.to_s).to eq("corrective_action.txt")
        expect(document.metadata[:description]).to eq(new_file_description)
      end

      context "when not adding a new file" do
        before { corrective_action_params[:file].delete(:file) }

        it "stored the new file with the description", :aggregate_failures do
          expect { update_corrective_action }.not_to raise_error
        end
      end
    end

    context "with a new file" do
      it "stored the new file with the description", :aggregate_failures do
        update_corrective_action

        document = corrective_action.reload.documents.first
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
