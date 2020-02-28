require "rails_helper"

RSpec.describe AuditActivity::Investigation::AddProject, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject do
    project.activities.find_by!(type: described_class.name)
  end

  let(:project) { create(:project) }


  describe "#build_title" do
    it "stores the title" do
      expect(subject.title).to eq("Project logged: #{project.decorate.title}")
    end
  end

  describe "#build_body" do
    it "stores the body" do
      expect(subject.body).to eq("**Project details**<br><br>#{project.description}<br><br>Assigned to #{project.assignee.display_name}.")
    end
  end
end
