FactoryBot.define do
  factory :product do
    name { "product name" }
    description { "product description" }
    category { Rails.application.config.product_constants["product_category"].sample }
    product_type { "product_type" }

    factory :product_iphone do
      product_code { 234 }
      name { "iPhone XS MAX" }
      webpage { "https://www.iphone.webpage" }
      product_type { "phone" }
      category { "phone category" }
      description { "iphone description" }
      country_of_origin { "United States" }
      batch_number { "1234" }
    end

    factory :product_iphone_3g do
      product_code { 345 }
      name { "iPhone" }
      product_type { "phone" }
      category { "phone" }
    end

    factory :product_samsung do
      product_code { 4524 }
      name { "galaxy" }
      product_type { "phone" }
      category { "phone" }
      description { "a phone by samsung" }
      country_of_origin { "Republic of Korea" }
    end
  end
end
