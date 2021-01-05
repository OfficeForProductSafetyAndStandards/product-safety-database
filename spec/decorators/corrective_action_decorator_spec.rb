require "rails_helper"

RSpec.describe CorrectiveActionDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:decorated_corrective_action) { corrective_action.decorate }

  let(:corrective_action) { build(:corrective_action, online_recall_information: online_recall_information) }
  let(:online_recall_information) { Faker::Internet.url(host: "example.com") }

  describe "#description" do
    include_examples "a formated text", :corrective_action, :details
  end

  describe "#online_recall_information" do
    context "with online recall information" do
      specify { expect(decorated_corrective_action.online_recall_information).to eq(online_recall_information) }
    end

    context "without online recall information" do
      let(:online_recall_information) { nil }

      specify { expect(decorated_corrective_action.online_recall_information).to eq("No recall information published online") }
    end
  end
end
