require "rails_helper"

RSpec.describe CorrectiveActionDecorator, :with_stubbed_mailer do
  subject(:decorated_corrective_action) { corrective_action.decorate }

  let(:corrective_action) { build(:corrective_action, online_recall_information:) }
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

  describe "#case_id" do
    it "returns the investigation pretty id" do
      expect(decorated_corrective_action.case_id).to eq(corrective_action.investigation.pretty_id)
    end
  end
end
