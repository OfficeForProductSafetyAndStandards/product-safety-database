# spec/models/active_model/types/business_list_spec.rb
require "rails_helper"

RSpec.describe ActiveModel::Types::BusinessList do
  before do
    stub_const("Business", Class.new do
      attr_reader :attributes

      define_method(:initialize) do |attributes = {}|
        @attributes = attributes
      end
    end)
  end

  describe "#cast" do
    let(:type) { described_class.new }

    context "when value is an array of Business objects" do
      let(:first_business) { Business.new(name: "Business 1") }
      let(:second_business) { Business.new(name: "Business 2") }
      let(:business_array) { [first_business, second_business] }

      it "returns the value as is" do
        expect(type.cast(business_array)).to eq(business_array)
      end
    end

    context "when value is an array of hashes" do
      let(:first_business_attributes) { { name: "Business 1" } }
      let(:second_business_attributes) { { name: "Business 2" } }
      let(:attributes_array) { [first_business_attributes, second_business_attributes] }

      it "returns an array of Business objects" do
        result = type.cast(attributes_array)
        expect(result.all? { |b| b.is_a?(Business) }).to be true
        expect(result.map(&:attributes)).to eq(attributes_array)
      end
    end
  end
end
