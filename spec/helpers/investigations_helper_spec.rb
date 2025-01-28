require "rails_helper"

RSpec.describe InvestigationsHelper do
  describe "#calculate_row_index" do
    context "with different investigation counters and row numbers" do
      it "calculates row index for first row" do
        expect(helper.calculate_row_index(1, 1)).to eq(4)
      end

      it "calculates row index for second row" do
        expect(helper.calculate_row_index(1, 2)).to eq(5)
      end

      it "calculates row index for third row" do
        expect(helper.calculate_row_index(1, 3)).to eq(6)
      end

      it "calculates row index for first row of second investigation" do
        expect(helper.calculate_row_index(2, 1)).to eq(7)
      end

      it "calculates row index for second row of second investigation" do
        expect(helper.calculate_row_index(2, 2)).to eq(8)
      end

      it "calculates row index for third row of second investigation" do
        expect(helper.calculate_row_index(2, 3)).to eq(9)
      end
    end
  end
end
