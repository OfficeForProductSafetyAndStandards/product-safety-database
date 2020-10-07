require "rails_helper"

RSpec.describe AddPhoneCallToCase, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:result) { described_class.call(investigation: investigation, user: user) }

  let(:user) { create :user }
  let(:investigation) { create :allegation }

  describe "#call" do
    context "when no investigation is provided" do
      let(:investigation) { nil }

      it { expect(result).to be_a_failure }
      it { expect(result.error).to eq("No investigation supplied") }
    end

    context "when no user is provided" do
      let(:user) { nil }

      it { expect(result).to be_a_failure }
      it { expect(result.error).to eq("No user supplied") }
    end
  end
end
