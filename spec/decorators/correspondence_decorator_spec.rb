RSpec.describe CorrespondenceDecorator, :with_stubbed_mailer do
  subject { build(:email, investigation: notification).decorate }

  let(:user)         { create(:user) }
  let(:notification) { create(:notification) }

  describe "#activity_cell_partial" do
    let(:partial) { subject.activity_cell_partial(viewing_user) }

    context "when the viewing user has the view protected details permission" do
      let(:viewing_user) { user }

      before do
        AddTeamToNotification.call!(
          user:,
          notification:,
          team: viewing_user.team,
          collaboration_class: Collaboration::Access::Edit
        )
      end

      it { expect(partial).to eq("activity_table_cell_with_link") }
    end

    context "when the viewing does not has the view protected details permission" do
      let(:viewing_user) { create(:user, team: create(:team)) }

      it { expect(partial).to eq("activity_table_cell_no_link") }
    end
  end
end
