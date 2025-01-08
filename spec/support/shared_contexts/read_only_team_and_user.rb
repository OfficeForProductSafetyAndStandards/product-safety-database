RSpec.shared_context "with read only team and user" do
  let(:read_only_team) { create(:team) }
  let(:read_only_user) { create(:user, :activated, has_viewed_introduction: true, team: read_only_team) }
end
