require "rails_helper"

# TODO: Refactor this test.
RSpec.describe LockInactiveUsersJob, type: :job do
  describe "#perform" do
    it "calls User.lock_inactive_users!" do
      allow(User).to receive(:lock_inactive_users!)

      described_class.new.perform

      expect(User).to have_received(:lock_inactive_users!)
    end
  end
end
