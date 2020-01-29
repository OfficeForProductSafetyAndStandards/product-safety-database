require "rails_helper"
require "shared_contexts/load_user"

RSpec.describe Users::CreateSession do
  include_context "load user"

  subject { described_class.call(user_service: user_service) }

  describe ".call" do
    it { expect(subject.user).to be user }
  end
end
