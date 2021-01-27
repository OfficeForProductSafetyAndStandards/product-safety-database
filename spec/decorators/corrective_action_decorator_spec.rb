require "rails_helper"

RSpec.describe CorrectiveActionDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:decorated_corrective_action) { corrective_action.decorate }

  let(:corrective_action) { create(:corrective_action) }

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
end
