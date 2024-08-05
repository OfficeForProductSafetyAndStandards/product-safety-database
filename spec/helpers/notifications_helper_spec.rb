require "rails_helper"
RSpec.describe NotificationsHelper, type: :helper do
  describe "#collaborator_access" do
    let(:edit_access) { Collaboration::Access::Edit }
    let(:read_only_access) { Collaboration::Access::ReadOnly }

    it 'returns "Edit" for edit access' do
      expect(helper.collaborator_access(edit_access)).to eq("Edit")
    end

    it 'returns "View" for read-only access' do
      expect(helper.collaborator_access(read_only_access)).to eq("View")
    end
  end
end
