require "rails_helper"

RSpec.describe InvestigationPolicy, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:policy) { described_class.new(collaborator, investigation) }

  let(:investigation) { create(:allegation) }

  describe "#show?" do
    let(:collaborator) { create(:team) }

    context "when a team has readonly access" do
      before do
        create(:read_only_collaboration, investigation: investigation, collaborator: collaborator)
      end

      it { is_expected.to be_show }
    end

    context "when a team has edit access" do
      before do
        create(:read_only_collaboration, investigation: investigation, collaborator: collaborator)
      end

      it { is_expected.to be_show }
    end

    context "when the team has neither edit nor view only access" do

    end
  end

end
