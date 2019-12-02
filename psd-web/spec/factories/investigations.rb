FactoryBot.define do
  factory :allegation, class: Investigation::Allegation do
    # pretty_id { "1902-0001" }
    description { Faker::Hipster.paragraphs.join("\n") }
    is_closed { false }
    product_category { Rails.application.config.product_constants["product_category"].sample }
    hazard_type { Rails.application.config.hazard_constants["hazard_type"].sample }
    type { "Investigation::Allegation" }
  end
end
