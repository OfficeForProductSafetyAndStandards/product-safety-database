FactoryBot.define do
  factory :complainant do
    email_address { "test@example.com" }
    name { "complainant name" }
    other_details { "some details" }
    phone_number { "1234567890" }
    complainant_type { Complainant::TYPES.keys.sample }
  end

  Complainant::TYPES.keys.each do |type|
    factory :"complainant_#{type}", parent: :complainant do
      complainant_type { type }
    end
  end
end
