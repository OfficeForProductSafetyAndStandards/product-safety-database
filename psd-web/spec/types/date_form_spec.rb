require "rails_helper"

RSpec.describe DateForm do
  subject(:active_model_type) { described_class.new }

  let(:value) do
    { day: 1, month: 2, year: 2019 }
  end

  describe "#cast" do
    context "when giving a date" do
      it { expect(active_model_type.cast(Date.new(2019, 2, 1))).to eq(Date.new(2019, 2, 1)) }
    end

    context "when all the date parts are present" do
      it { expect(active_model_type.cast(value)).to eq(Date.new(2019, 2, 1)) }
    end

    context "when not all the date parts are present" do
      it { expect(active_model_type.cast(value.except(:year))).to be nil }
    end
  end
end
