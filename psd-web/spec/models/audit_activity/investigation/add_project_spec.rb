require "rails_helper"

RSpec.describe AuditActivity::Investigation::AddProject, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:activity) do
    project.activities.find_by!(type: described_class.name)
  end

  let(:project) { create(:project) }


  describe "#build_title" do
    it "stores the title" do
      expect(activity.title).to eq("Project logged: #{project.decorate.title}")
    end
  end

  describe "#build_body" do
    it "stores the body" do
      expect(activity.body).to eq("**Project details**<br><br>#{project.description}<br><br>Case owner: #{project.assignee.display_name}")
    end

    context "when case is coronavirus related" do
      let(:project) { create(:project, coronavirus_related: true) }

      it "adds text to the body" do
        expect(activity.body).to eq("**Project details**<br><br>Case is related to the coronavirus outbreak.<br><br>#{project.description}<br><br>Case owner: #{project.assignee.display_name}")
      end
    end
  end
end
