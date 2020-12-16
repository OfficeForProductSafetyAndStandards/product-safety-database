require "rails_helper"

RSpec.describe GtinValidator do
  subject(:record) do
    Class.new {
      include ActiveModel::Validations
      attr_accessor :gtin
      validates :gtin,
                gtin: true

      def self.name
        "Test class"
      end
    }.new
  end

  context "with a valid 8 digits UPC-E" do
    before { record.gtin = "02345673" }

    it { is_expected.to be_valid }
  end

  context "with a valid 8 digits EAN8" do
    before { record.gtin = "40123455" }

    it { is_expected.to be_valid }
  end

  context "with a valid 12 digit UPC-A number" do
    before { record.gtin = "012345678912" }

    it "is valid" do
      expect(record).to be_valid
    end
  end

  context "with a valid 13 digit EAN-13 number" do
    before { record.gtin = "0012345678912" }

    it "is valid" do
      expect(record).to be_valid
    end
  end

  context "with an invalid 12 digit UPC-A number (wrong checkdigit)" do
    before { record.gtin = "012345678919" }

    it "is not valid and adds an error", :aggregate_failures do
      expect(record).not_to be_valid
      expect(record.errors.details[:gtin]).to eq [{ error: :invalid }]
    end
  end

  context "with an invalid 13 digit EAN-13 number (wrong checkdigit)" do
    before { record.gtin = "0012345678919" }

    it "is not valid and adds an error", :aggregate_failures do
      expect(record).not_to be_valid
      expect(record.errors.details[:gtin]).to eq [{ error: :invalid }]
    end
  end

  context "when nil" do
    before { record.gtin = nil }

    # Valid as presence validation can be performed separately
    it "is valid" do
      expect(record).to be_valid
    end
  end
end
