require "rails_helper"

RSpec.describe ActivityDecorator do
  describe "#protected_details_type" do
    it 'returns "notification contact details"' do
      activity = Activity.new
      decorator = described_class.decorate(activity)
      expect(decorator.protected_details_type).to eq("notification contact details")
    end
  end
end
