require "rails_helper"

RSpec.describe CorrectiveActionDecorator do
  subject { corrective_action.decorate }

  let(:corrective_action) { CorrectiveAction.new }

  describe "#description" do
    include_examples "a formated text", :corrective_action, :details
  end
end
