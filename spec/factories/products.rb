FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    description { "product description" }
    category { Rails.application.config.product_constants["product_category"].sample }
    product_type { "product_type" }
    gtin13 { "9781529034523" }
    authenticity { Product.authenticities.keys.sample }
    batch_number { "123123123" }

    factory :product_iphone do
      product_code { 234 }
      name { "iPhone XS MAX" }
      webpage { "https://www.iphone.webpage" }
      product_type { "phone" }
      category { "Communication and media equipment" }
      description { "iphone description" }
      country_of_origin { "United States" }
      batch_number { "1234" }
    end

    factory :product_iphone_3g do
      product_code { 345 }
      name { "iPhone" }
      product_type { "phone" }
      category { "Communication and media equipment" }
    end

    factory :product_samsung do
      product_code { 4524 }
      name { "galaxy" }
      product_type { "phone" }
      category { "Communication and media equipment" }
      description { "a phone by samsung" }
      country_of_origin { "Republic of Korea" }
    end

    factory :product_washing_machine do
      product_code { Faker::Number.number(digits: 10).to_s }
      name { Faker::Lorem.sentence }
      product_type { "Washing machine" }
      category { "Electrical appliances and equipment" }
      description { Faker::Lorem.paragraph }
      country_of_origin { Country.all.sample }
    end
  end
end
