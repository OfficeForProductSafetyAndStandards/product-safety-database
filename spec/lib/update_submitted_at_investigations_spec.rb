# rubocop:disable RSpec/DescribeClass
require "rails_helper"
require "rake"
Rails.application.load_tasks

RSpec.describe "investigations:update_submitted_date", :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let!(:investigation_with_submitted_at) do
    travel_to(2.days.ago) do
      create(:notification, submitted_at: 2.days.from_now)
    end
  end
  let!(:investigation_with_nil_submitted_at) do
    travel_to(1.day.ago) do
      create(:notification, submitted_at: nil)
    end
  end

  before do
    # Clear the task before each test to ensure it can be re-invoked
    Rake.application["investigations:update_submitted_date"].reenable
  end

  it "updates submitted_at with created_at for investigations where submitted_at is nil" do
    # Run the task
    Rake::Task["investigations:update_submitted_date"].invoke

    # Reload the objects to get the updated values
    investigation_with_nil_submitted_at.reload
    investigation_with_submitted_at.reload

    # Expectations
    expect(investigation_with_nil_submitted_at.submitted_at).to eq(investigation_with_nil_submitted_at.created_at)
    expect(investigation_with_submitted_at.submitted_at).not_to eq(investigation_with_submitted_at.created_at)
  end
end
# rubocop:enable RSpec/DescribeClass
