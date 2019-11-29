FactoryBot.define do
  factory :allegation, class: Investigation::Allegation do
    pretty_id { "1902-0001" }
    description { "test" }
    is_closed { false }
  end
end
