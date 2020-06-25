require "rails_helper"

RSpec.describe RadioItemsHelper do
  describe "#radio_items_from_hash" do
    let(:hash_to_convert) do
      {
        option_a: "Choose option A",
        option_b: "Choose option B"
      }
    end

    it "transforms hash into text/value list of radio items" do
      expect(helper.radio_items_from_hash(hash_to_convert)).to eq(
        [
          { text: "Choose option A", value: :option_a },
          { text: "Choose option B", value: :option_b },
        ]
      )
    end
  end
end
