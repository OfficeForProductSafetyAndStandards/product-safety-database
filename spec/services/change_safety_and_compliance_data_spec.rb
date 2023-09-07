require "rails_helper"

RSpec.describe ChangeSafetyAndComplianceData, :with_stubbed_mailer, :with_stubbed_antivirus, :with_test_queue_adapter do
  let!(:investigation) do
    create(:allegation, reported_reason: :unsafe_and_non_compliant,
                        hazard_type: "Burns",
                        hazard_description: "Too hot",
                        non_compliant_reason: "Breaks all the rules")
  end

  let(:hazard_type) { nil }
  let(:hazard_description) { nil }
  let(:non_compliant_reason) { nil }

  let(:user) { create(:user, name: "User One") }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no investigation parameter" do
      let(:result) { described_class.call(user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(investigation:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with the required parameters" do
      let(:result) do
        described_class.call(
          user:,
          investigation:,
          hazard_type:,
          hazard_description:,
          non_compliant_reason:,
          reported_reason:
        )
      end

      let(:activity_entry) { investigation.activities.where(type: AuditActivity::Investigation::ChangeSafetyAndComplianceData.to_s).order(:created_at).last }

      context "when reported_reason is `safe_and_compliant`" do
        let(:reported_reason) { :safe_and_compliant }

        context "with updated values" do
          before do
            result
          end

          it "updates reported_reason" do
            expect(investigation.reported_reason).to eq("safe_and_compliant")
          end

          it "makes hazard_type nil" do
            expect(investigation.hazard_type).to eq(nil)
          end

          it "makes hazard_description nil" do
            expect(investigation.hazard_description).to eq(nil)
          end

          it "makes non_compliant_reason nil" do
            expect(investigation.non_compliant_reason).to eq(nil)
          end

          it "creates an activity entry" do
            expect(activity_entry.metadata).to eql({
              "updates" => { "reported_reason" => %w[unsafe_and_non_compliant safe_and_compliant],
                             "hazard_type" => ["Burns", nil],
                             "hazard_description" => ["Too hot", nil],
                             "non_compliant_reason" => ["Breaks all the rules", nil] }
            })
          end
        end

        it "sends an email to notify of the change" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(
            investigation.pretty_id,
            investigation.owner_team.name,
            investigation.owner_team.email,
            "#{user.name} (#{user.team.name}) edited safety and compliance data on the case.",
            "Safety and compliance data edited for Case"
          )
        end
      end

      context "when reported_reason is `unsafe_and_non_compliant`" do
        let(:reported_reason) { :unsafe_and_non_compliant }
        let(:hazard_type) { "Cuts" }
        let(:hazard_description) { "Too Sharp" }
        let(:non_compliant_reason) { "Breaks all the requirements" }

        context "with updated values" do
          before do
            result
          end

          it "updates reported_reason" do
            expect(investigation.reported_reason).to eq("unsafe_and_non_compliant")
          end

          it "updates hazard_type" do
            expect(investigation.hazard_type).to eq(hazard_type)
          end

          it "updates hazard_description" do
            expect(investigation.hazard_description).to eq(hazard_description)
          end

          it "updates non_compliant_reason" do
            expect(investigation.non_compliant_reason).to eq(non_compliant_reason)
          end

          it "creates an activity entry" do
            expect(activity_entry.metadata).to eql({
              "updates" => {
                "hazard_type" => %w[Burns Cuts],
                "hazard_description" => ["Too hot", "Too Sharp"],
                "non_compliant_reason" => ["Breaks all the rules", "Breaks all the requirements"]
              }
            })
          end
        end

        it "sends an email to notify of the change" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(
            investigation.pretty_id,
            investigation.owner_team.name,
            investigation.owner_team.email,
            "#{user.name} (#{user.team.name}) edited safety and compliance data on the case.",
            "Safety and compliance data edited for Case"
          )
        end
      end

      context "when reported_reason is `unsafe`" do
        let(:reported_reason) { :unsafe }
        let(:hazard_type) { "Cuts" }
        let(:hazard_description) { "Too Sharp" }

        context "with updated values" do
          before do
            result
          end

          it "updates reported_reason" do
            expect(investigation.reported_reason).to eq("unsafe")
          end

          it "updates hazard_type" do
            expect(investigation.hazard_type).to eq(hazard_type)
          end

          it "updates hazard_description" do
            expect(investigation.hazard_description).to eq(hazard_description)
          end

          it "makes non_compliant_reason nil" do
            expect(investigation.non_compliant_reason).to eq(nil)
          end

          it "creates an activity entry" do
            expect(activity_entry.metadata).to eq({
              "updates" => { "reported_reason" => %w[unsafe_and_non_compliant unsafe],
                             "hazard_type" => %w[Burns Cuts],
                             "hazard_description" => ["Too hot", "Too Sharp"],
                             "non_compliant_reason" => ["Breaks all the rules", nil] }
            })
          end
        end

        it "sends an email to notify of the change" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(
            investigation.pretty_id,
            investigation.owner_team.name,
            investigation.owner_team.email,
            "#{user.name} (#{user.team.name}) edited safety and compliance data on the case.",
            "Safety and compliance data edited for Case"
          )
        end
      end

      context "when reported_reason is `non_compliant`" do
        let(:reported_reason) { :non_compliant }
        let(:non_compliant_reason) { "Did not fill out the forms" }

        context "with updated values" do
          before do
            result
          end

          it "updates reported_reason" do
            expect(investigation.reported_reason).to eq("non_compliant")
          end

          it "makes hazard_type nil" do
            expect(investigation.hazard_type).to eq(nil)
          end

          it "makes hazard_description nil" do
            expect(investigation.hazard_description).to eq(nil)
          end

          it "updates non_compliant_reason" do
            expect(investigation.non_compliant_reason).to eq(non_compliant_reason)
          end

          it "creates an activity entry" do
            expect(activity_entry.metadata).to eql({
              "updates" => { "reported_reason" => %w[unsafe_and_non_compliant non_compliant],
                             "hazard_type" => ["Burns", nil],
                             "hazard_description" => ["Too hot", nil],
                             "non_compliant_reason" => ["Breaks all the rules", non_compliant_reason] }
            })
          end
        end

        it "sends an email to notify of the change" do
          expect { result }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(
            investigation.pretty_id,
            investigation.owner_team.name,
            investigation.owner_team.email,
            "#{user.name} (#{user.team.name}) edited safety and compliance data on the case.",
            "Safety and compliance data edited for Case"
          )
        end
      end
    end
  end
end
