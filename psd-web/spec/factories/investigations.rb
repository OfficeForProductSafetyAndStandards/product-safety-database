FactoryBot.define do
  factory :allegation, class: Investigation::Allegation do
    description { "test" }
    is_closed { false }
  end
end
