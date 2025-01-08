require "rails_helper"

RSpec.describe Investigation::Project do
  subject(:project) { build(:project) }

  describe "#case_type" do
    it "returns 'project'" do
      expect(project.case_type).to eq("project")
    end
  end
end
