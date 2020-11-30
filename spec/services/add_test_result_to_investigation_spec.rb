require "rails_helper"

RSpec.describe AddTestResultToInvestigation, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus, :with_test_queue_adapter do
  let(:user)                                 { create(:user, :activated) }
  let!(:investigation)                       { create :allegation, creator: user }

  let(:file)                                 { ActiveStorage::Blob.create_after_upload!(io: StringIO.new("files/test_result.txt"), filename: "test_result.txt") }
  let(:file_description)                     { Faker::Hipster.sentence }
  let(:document)                             { instance_double(FileField, file: file, description: file_description) }
  let(:date)                                 { Date.current }
  let(:details)                              { Faker::Hipster.sentence }
  let(:legislation)                          { Rails.application.config.legislation_constants["legislation"].sample }
  let(:test_result)                          { Test::Result.results[:passed] }
  let(:standards_product_was_tested_against) { %w[EN71] }
  let(:product_id)                           { create(:product).id }
  let(:params) do
    {
      investigation: investigation,
      user: user,
      document: document,
      date: date,
      details: details,
      legislation: legislation,
      result: test_result,
      standards_product_was_tested_against: standards_product_was_tested_against,
      product_id: product_id
    }
  end

  def expected_email_body(user, viewing_user)
    "Test result was added to the #{investigation.case_type} by #{UserSource.new(user: user).show(viewing_user)}."
  end

  def expected_email_subject
    "#{investigation.case_type.upcase_first} updated"
  end

  describe "when provided with a user and an investigation" do
    let(:command) { described_class.call(params) }

    it "creates the test result", :aggregate_failures do
      expect(command).to be_a_success

      expect(command.test_result).to have_attributes(
        date: date, details: details, legislation: legislation, result: "passed", product_id: product_id,
        standards_product_was_tested_against: standards_product_was_tested_against,
        document_blob: document.file
      )
    end

    it "creates an audit log", :aggregate_failures do
      test_result = command.test_result
      audit = investigation.activities.find_by!(type: "AuditActivity::Test::Result", product_id: product_id)
      expect(audit.source.user).to eq(user)
      expect(audit.metadata["test_result_id"]).to eq(test_result.id)
    end

    shared_examples "a service which notifies teams with access" do
      let(:team_with_edit_access_email)     { Faker::Internet.unique.safe_email }
      let(:team_with_readonly_access_email) { Faker::Internet.unique.safe_email }
      let(:team_with_edit_access)           { create(:team, team_recipient_email: team_with_edit_access_email) }
      let(:team_with_readonly_access)       { create(:team, team_recipient_email: team_with_readonly_access_email) }
      let(:user_with_edit_access)           { create(:user, :activated, team: team_with_readonly_access) }
      let(:user_with_readonly_access)       { create(:user, :activated, team: team_with_readonly_access) }

      before do
        AddTeamToCase.call!(
          user: user,
          investigation: investigation,
          team: team_with_edit_access,
          collaboration_class: Collaboration::Access::Edit
        )
        AddTeamToCase.call!(
          user: user,
          investigation: investigation,
          team: team_with_readonly_access,
          collaboration_class: Collaboration::Access::ReadOnly
        )
      end

      context "when the user is the owner" do
        context "when the team has team recipient email" do
          let(:expected_edit_notification_args) do
            [
              investigation.pretty_id,
              team_with_edit_access.name,
              team_with_edit_access.email,
              expected_email_body(user, team_with_edit_access),
              expected_email_subject
            ]
          end

          let(:expected_readonly_notification_args) do
            [
              investigation.pretty_id,
              team_with_readonly_access.name,
              team_with_readonly_access.email,
              expected_email_body(user, team_with_readonly_access),
              expected_email_subject
            ]
          end

          it "notifies the teams with a read only or edit access to the case", :aggregate_failures do
            expect { result }
              .to  have_enqueued_mail(NotifyMailer, :investigation_updated)
                     .with(a_hash_including(args: expected_edit_notification_args))
                     .and have_enqueued_mail(NotifyMailer, :investigation_updated)
                            .with(a_hash_including(args: expected_readonly_notification_args))
          end
        end

        context "when the team does not have a team recipient email" do
          let(:team_with_edit_access_email)     { nil }
          let(:team_with_readonly_access_email) { nil }
          let(:expected_edit_notification_args) do
            [
              investigation.pretty_id,
              user_with_edit_access.name,
              user_with_edit_access.email,
              expected_email_body(user, user_with_edit_access),
              expected_email_subject
            ]
          end

          let(:expected_readonly_notification_args) do
            [
              investigation.pretty_id,
              user_with_readonly_access.name,
              user_with_readonly_access.email,
              expected_email_body(user, user_with_readonly_access),
              expected_email_subject
            ]
          end

          it "notifies the teams with a read only or edit access to the case", :aggregate_failures do
            expect { result }
              .to  have_enqueued_mail(NotifyMailer, :investigation_updated)
                     .with(a_hash_including(args: expected_edit_notification_args))
                     .and have_enqueued_mail(NotifyMailer, :investigation_updated)
                            .with(a_hash_including(args: expected_readonly_notification_args))
          end
        end
      end
    end

    it_behaves_like "a service which notifies teams with access" do
      let(:result) { described_class.call(params) }
    end
  end
end
