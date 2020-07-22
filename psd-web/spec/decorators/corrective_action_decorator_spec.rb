require "rails_helper"

RSpec.describe CorrectiveActionDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject { corrective_action.decorate }

  let(:corrective_action) { CorrectiveAction.new }

  describe "#description" do
    include_examples "a formated text", :corrective_action, :details
  end

  describe "#has_document?" do
    context "with a document" do
      let(:corrective_action) { create(:corrective_action, :with_file) }

      it { is_expected.to have_document }
    end

    context "without a document" do
      let(:corrective_action) { create(:corrective_action) }

      it { is_expected.not_to have_document }
    end
  end
end
