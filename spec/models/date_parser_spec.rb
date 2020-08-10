require "rails_helper"

RSpec.describe DateParser do
  subject { described_class.new(input).date }

  context "when given a date object" do
    let(:input) { Date.new(2020, 1, 20) }

    it { is_expected.to eql(input) }
  end

  context "when given a hash containing a valid year, month and day" do
    let(:input) { { year: "2020", month: "1 ", day: "20 " } }

    it { is_expected.to eql(Date.new(2020, 1, 20)) }
  end

  context "when given a hash containing invalid year, month and day numbers" do
    let(:input) { { year: "2020", month: "1", day: "32" } }

    it { is_expected.to eql(OpenStruct.new(year: "2020", month: "1", day: "32")) }
  end

  context "when given a hash containing a large day" do
    let(:input) { { year: "1", month: "1", day: "11111110110" } }

    it { is_expected.to eql(OpenStruct.new(year: "1", month: "1", day: "11111110110")) }
  end

  context "when given a hash containing a large year" do
    let(:input) { { year: "11111110110", month: "1", day: "1" } }

    it { is_expected.to eql(Date.new(11_111_110_110, 1, 1,)) }
  end

  context "when given a hash containing non-numeric strings" do
    let(:input) { { year: "2020", month: "1", day: "20?" } }

    it { is_expected.to eql(OpenStruct.new(year: "2020", month: "1", day: "20?")) }
  end

  context "when given blank strings" do
    let(:input) { { year: "", month: "", day: "" } }

    it { is_expected.to be_nil }
  end

  context "when given nil" do
    let(:input) { nil }

    it { is_expected.to be_nil }
  end
end
