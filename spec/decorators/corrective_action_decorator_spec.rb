require "rails_helper"

RSpec.describe CorrectiveActionDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:decorated_corrective_action) { corrective_action.decorate }

  let(:corrective_action) { build(:corrective_action, online_recall_information: online_recall_information) }
  let(:online_recall_information) { Faker::Internet.url(host: "example.com") }

  describe "#description" do
    include_examples "a formated text", :corrective_action, :details
  end
end
