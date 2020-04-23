require "rails_helper"

RSpec.describe UserDecorator do
  subject(:decorated_user) { user.decorate }

  let(:user) { build(:user) }


  describe "#assignee_short_name" do
    let(:viewing_user) { build(:user, organisation: organisation) }

    context "when viewing from a user within the same organisation" do
      let(:organisation) { user.organisation }

      it { expect(decorated_user.assignee_short_name(viewing_user: viewing_user)).to eq(user.name) }
    end

    context "when viewing from a user within another organisation" do
      let(:organisation) { build(:organisation) }

      it { expect(decorated_user.assignee_short_name(viewing_user: viewing_user)).to eq(user.organisation.name) }
    end
  end

  describe "#name" do
    context "when the user is deleted" do
      let(:user) { build_stubbed(:user, name: "Foo Bar", deleted: true) }

      it "returns user name with a tag after their name" do
        expect(decorated_user.name).to eq("Foo Bar [user deleted]")
      end
    end

    it "non deleted users show their name" do
      expect(decorated_user.name).to eq(user.name)
    end
  end
end
