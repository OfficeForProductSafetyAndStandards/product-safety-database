FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    description { "product description" }
    category { Rails.application.config.product_constants["product_category"].sample }
    subcategory { "subcategory" }
    barcode { "9781529034523" }
    authenticity { Product.authenticities.keys.without("unsure").sample }
    brand { Faker::Company.name }
    has_markings { Product.has_markings.keys.sample }
    markings { [Product::MARKINGS.sample] }
    when_placed_on_market { "before_2021" }
    country_of_origin { "United Kingdom" }

    trait :with_versions do
      transient do
        new_description { "new product description" }
      end

      after(:create) do |product, evaluator|
        product.update!(description: evaluator.new_description)
      end
    end

    trait :retired do
      after(:create) do |product, _|
        product.mark_as_retired!
      end
    end

    factory :product_iphone do
      product_code { 234 }
      name { "iPhone XS MAX" }
      category { "Communication and media equipment" }
      subcategory { "phone" }
      description { "iphone description" }
      webpage { "https://www.iphone.webpage" }
      country_of_origin { "United States" }
    end

    factory :product_iphone_3g do
      product_code { 345 }
      name { "iPhone" }
      category { "Communication and media equipment" }
      subcategory { "phone" }
    end

    factory :product_samsung do
      product_code { 4524 }
      name { "galaxy" }
      category { "Communication and media equipment" }
      subcategory { "phone" }
      description { "a phone by samsung" }
      country_of_origin { "Republic of Korea" }
    end

    factory :product_washing_machine do
      product_code { Faker::Number.number(digits: 10).to_s }
      name { Faker::Lorem.sentence }
      category { "Electrical appliances and equipment" }
      subcategory { "Washing machine" }
      description { Faker::Lorem.paragraph }
      webpage { "https://www.washingmachine.webpage" }
      country_of_origin { Country.all.sample }
    end
  end
end
