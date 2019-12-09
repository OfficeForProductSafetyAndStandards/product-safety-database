require "rails_helper"

RSpec.describe CorrectiveActionDecorator do
  let(:corrective_action) { CorrectiveAction.new }

  subject { corrective_action.decorate }

  describe "#description" do
    include_examples "a formated text", :corrective_action, :details
  end
end
