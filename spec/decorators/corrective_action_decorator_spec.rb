require "rails_helper"

RSpec.describe CorrectiveActionDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:decorated_corrective_action) { corrective_action.decorate }

  let(:corrective_action) { build(:corrective_action, online_recall_information: online_recall_information) }
  let(:online_recall_information) { Faker::Internet.url(host: "example.com") }

  describe "#description" do
    include_examples "a formated text", :corrective_action, :details
  end

  describe "#geographic_scopes" do
    let(:expected_corrective_action_scopes) do
      corrective_action.geographic_scopes.map { |geographic_scope| I18n.t(geographic_scope, scope: %i[corrective_action attributes geographic_scopes]) }.to_sentence
    end

    it "displays the translated geographical scopes" do
      expect(decorated_corrective_action.geographic_scopes).to eq(expected_corrective_action_scopes)
    end
  end

  describe "#date_of_activity_for_sorting" do
    specify do
      expect(decorated_corrective_action.date_of_activity_for_sorting).to eq(corrective_action.date_decided)
    end
  end

  describe "#online_recall_information" do
    context "when online_recall_information includes a protocol" do
      it "returns online_recall_information" do
        expect(decorated_corrective_action.online_recall_information).to eq(online_recall_information)
      end
    end

    context "when online_recall_information does not include a protocol" do
      let(:online_recall_information) { "example.com" }

      it "prepends `http://` to online_recall_information" do
        expect(decorated_corrective_action.online_recall_information).to eq("http://#{online_recall_information}")
      end
    end
  end
end
