require "rails_helper"

RSpec.describe Registration do
  let(:name) { Faker::Movies::LordOfTheRings.character }
  let(:mobile_number) { Faker::PhoneNumber.cell_phone }
  let(:password) { Faker::Internet.password  }

  it "registers a new user" do
    visit new_user_registrations_path

    fill_in "user[name]", with: name
    fill_in "user[mobile_number]", with: mobile_number
    fill_in "user[password]", with: password
    click_on "Continue"
  end
end
