require "rails_helper"

RSpec.describe RecentDateValidator do
  context "with default window" do
    subject(:validator) do
      Class.new {
        include ActiveModel::Validations
        attr_accessor :date

        validates :date, recent_date: { message: "Date not recent" }

        def self.name
          "RecentDateValidatorSpec"
        end
      }.new
    end

    valid_dates = [
      Date.new(1970, 1, 1),
      Date.new(2020, 2, 3),
      Time.zone.today + 50.years
    ]

    valid_dates.each do |date|
      context "with valid date #{date}" do
        before do
          validator.date = date
          validator.validate
        end

        it "is valid" do
          expect(validator).to be_valid
        end

        it "does not populate an error message" do
          expect(validator.errors[:date]).to be_empty
        end
      end
    end

    invalid_dates = [
      Date.new(1969, 1, 1),
      Date.new(1969, 12, 31),
      Time.zone.today + 50.years + 1.day,
      Time.zone.today + 60.years
    ]

    invalid_dates.each do |date|
      context "with invalid date #{date}" do
        before do
          validator.date = date
          validator.validate
        end

        it "is not valid" do
          expect(validator).not_to be_valid
        end

        it "populates an error message" do
          expect(validator.errors[:date]).to eq ["Date not recent"]
        end
      end
    end
  end

  context "with custom window" do
    subject(:validator) do
      Class.new {
        include ActiveModel::Validations
        attr_accessor :date

        validates :date,
                  recent_date: {
                    message: "Date not recent",
                    on_or_after: Date.new(1960, 1, 1),
                    on_or_before: Date.new(2000, 12, 31)
                  }

        def self.name
          "RecentDateValidatorSpec"
        end
      }.new
    end

    valid_dates = [
      Date.new(1960, 1, 1),
      Date.new(1969, 12, 31),
      Date.new(2000, 12, 31)
    ]

    valid_dates.each do |date|
      context "with valid date #{date}" do
        before do
          validator.date = date
          validator.validate
        end

        it "is valid" do
          expect(validator).to be_valid
        end

        it "does not populate an error message" do
          expect(validator.errors[:date]).to be_empty
        end
      end
    end

    invalid_dates = [
      Date.new(1950, 1, 1),
      Date.new(1959, 12, 31),
      Date.new(2001, 1, 1),
      Date.new(2021, 12, 31)
    ]

    invalid_dates.each do |date|
      context "with invalid date #{date}" do
        before do
          validator.date = date
          validator.validate
        end

        it "is not valid" do
          expect(validator).not_to be_valid
        end

        it "populates an error message" do
          expect(validator.errors[:date]).to eq ["Date not recent"]
        end
      end
    end
  end

  context "with on_or_after set to false" do
    subject(:validator) do
      Class.new {
        include ActiveModel::Validations
        attr_accessor :date

        validates :date,
                  recent_date: {
                    message: "Date not recent",
                    on_or_after: false
                  }

        def self.name
          "RecentDateValidatorSpec"
        end
      }.new
    end

    it "does not check dates before 1970" do
      validator.date = Date.new(1969, 12, 31)
      validator.validate
      expect(validator).to be_valid
    end
  end

  context "with on_or_before set to false" do
    subject(:validator) do
      Class.new {
        include ActiveModel::Validations
        attr_accessor :date

        validates :date,
                  recent_date: {
                    message: "Date not recent",
                    on_or_before: false
                  }

        def self.name
          "RecentDateValidatorSpec"
        end
      }.new
    end

    it "does not check dates over 50 years in the future" do
      validator.date = Time.zone.today + 50.years + 1.day
      validator.validate
      expect(validator).to be_valid
    end
  end
end
