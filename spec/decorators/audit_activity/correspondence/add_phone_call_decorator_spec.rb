require "rails_helper"

RSpec.describe AuditActivity::Correspondence::AddPhoneCall do
  subject(:decorated_activity) { correspondence.decorate }

  let(:investigation)  { create(:allegation) }

  let(:correspondence) { build(:correspondence_phone_call, investigation: investigation) }
  let(:source)         { create(:user_source, sourceable: correspondence) }
  let(:viewing_user)   { create(:user) }

  before do
    # byebug
  end

  describe "#phone_call_by" do
    it { expect(decorated_activity.phone_call_by(viewing_user)).to eq("Phone call by #{correspondence.subtitle(source.user)}") }
  end
end
