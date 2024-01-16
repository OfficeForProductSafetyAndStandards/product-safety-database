RSpec.describe ChangeNotificationReferenceNumber, :with_test_queue_adapter do
  subject(:result) { described_class.call!(notification:, reference_number:, user:) }

  let!(:notification) { create(:notification, complainant_reference: previous_reference_number, creator: user) }
  let(:previous_reference_number) { "Case name" }
  let(:reference_number) { "New case name" }
  let(:user) { create(:user, :activated) }
  let(:other_team) { create(:team) }
  let(:other_user) { create(:user, :activated, team: other_team) }

  context "with no notification parameter" do
    subject(:result) { described_class.call(user:, reference_number:) }

    it "fails" do
      expect(result).to be_failure
    end
  end

  context "with no user parameter" do
    subject(:result) { described_class.call(notification:, reference_number:) }

    it "fails" do
      expect(result).to be_failure
    end
  end

  context "with no reference_number parameter" do
    subject(:result) { described_class.call(notification:, user:) }

    it "fails" do
      expect(result).to be_failure
    end
  end

  context "when the previous and the new name are the same" do
    subject(:result) { described_class.call!(notification:, reference_number: previous_reference_number, user:) }

    it "succeeds" do
      expect(result).to be_success
    end

    it "does not create a new activity" do
      expect { result }.not_to change(Activity, :count)
    end
  end

  context "when the previous reference_number and the new reference_number are different" do
    it "succeeds" do
      expect(result).to be_success
    end

    it "changes the reference_number for the notification" do
      expect { result }.to change(notification, :complainant_reference).from(previous_reference_number).to(reference_number)
    end

    it "creates a new activity for the change", :aggregate_failures do
      expect { result }.to change(Activity, :count).by(1)
      activity = notification.reload.activities.first
      expect(activity).to be_a(AuditActivity::Investigation::UpdateReferenceNumber)
      expect(activity.added_by_user).to eq(user)
    end
  end
end
