require "test_helper"

class EnquiryTest < ActiveSupport::TestCase
  setup do
    @user = users(:opss)
  end

  test "Enquiry with valid date received" do
    investigation = Investigation::Enquiry.new("date_received_day" => 1, "date_received_month" => 1, "date_received_year" => 1, owner: @user)
    assert(investigation.valid?(:about_enquiry))
  end

  test "Enquiry date received can be nil, for old enquiries" do
    investigation = Investigation::Enquiry.new("date_received" => nil, owner: @user)
    assert(investigation.valid?)
  end

  test "Enquiry date received cannot be in the future" do
    investigation = Investigation::Enquiry.new("date_received" => Time.zone.today + 1.year, owner: @user)
    assert(investigation.invalid?(:about_enquiry))
  end

  test "Enquiry date received cannot be in the future 2" do
    investigation = Investigation::Enquiry.new("date_received_day" => 1, "date_received_month" => 1, "date_received_year" => 9999, owner: @user)
    assert(investigation.invalid?(:about_enquiry))
  end

  test "Enquiry date received cannot have empty fields" do
    investigation = Investigation::Enquiry.new("date_received_day" => 1, "date_received_month" => 1, "date_received_year" => "", owner: @user)
    assert(investigation.invalid?(:about_enquiry))
  end

  test "Enquiry date received has to be a date" do
    investigation = Investigation::Enquiry.new("date_received_day" => "day", "date_received_month" => "month", "date_received_year" => "year", owner: @user)
    assert(investigation.invalid?(:about_enquiry))
  end
end
