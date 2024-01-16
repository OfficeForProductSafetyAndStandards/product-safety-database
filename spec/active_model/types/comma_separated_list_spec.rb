RSpec.describe ActiveModel::Types::CommaSeparatedList do
  subject(:type_caster) { described_class.new }

  context "when passing a string without comma" do
    let(:value) { "a string" }

    it "returns the an array with the passed in string" do
      expect(type_caster.cast(value)).to eq(["a string"])
    end
  end

  context "when passing a empty comma" do
    let(:value) { "a string, , ," }

    it "returns the an array with the passed in string" do
      expect(type_caster.cast(value)).to eq(["a string"])
    end
  end

  context "when passing a string with commas separated values" do
    let(:value) { "a string, another string" }

    it "returns the an array with the passed in strings" do
      expect(type_caster.cast(value)).to eq(["a string", "another string"])
    end
  end

  context "when passing an empty string" do
    let(:value) { "" }

    it "returns an empty array" do
      expect(type_caster.cast(value)).to eq([])
    end
  end

  context "when passing a nil value" do
    let(:value) { nil }

    it "returns an empty array" do
      expect(type_caster.cast(value)).to eq([])
    end
  end
end
