require "rails_helper"

RSpec.describe "Welcome Flipper", type: :feature do
  let(:user) { create(:user) }

  before do
    Flipper.instance = nil
    Flipper.configure do |config|
      config.default { Flipper.new(Flipper::Adapters::Memory.new) }
    end
  end

  describe "test flipper feature flag behavior" do
    context "when feature is enabled" do
      before do
        Flipper.enable(:welcome)
      end

      it "has welcome feature enabled" do
        expect(Flipper.enabled?(:welcome)).to be true
      end

      it "has welcome feature enabled for a specified user" do
        expect(Flipper.enabled?(:welcome, user)).to be true
      end
    end

    context "when feature is disabled" do
      before do
        Flipper.disable(:welcome)
      end

      it "has welcome feature disabled" do
        expect(Flipper.enabled?(:welcome)).to be false
      end

      it "has welcome feature disabled for a specific user" do
        expect(Flipper.enabled?(:welcome, user)).to be false
      end
    end
  end
end
