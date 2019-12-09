require "rails_helper"

RSpec.describe AuditActivity::Investigation::AddProject, :with_stubbed_elasticsearch do
  let(:project) { create(:project) }

  subject do
    project.activities.find_by!(type: "AuditActivity::Investigation::AddProject")
  end


  describe '#build_title' do
    it "stores the title" do
      expect(subject.title).to eq("Project logged: #{project.decorate.title}")
    end
  end

  describe "#build_body" do
    it "stores the body" do
      expect(subject.body).to eq("**Project details**<br><br>#{project.description}")
    end
  end

end
