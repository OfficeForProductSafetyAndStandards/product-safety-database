namespace :data_migration do
  desc "Update product category for investigations and products"
  task update_product_category: :environment do
    Investigation
      .where(product_category: "Protective equipment")
      .unscoped
      .update_all(product_category: "Personal protective equipment (PPE)")

    Product
      .where(category: "Protective equipment")
      .update_all(category: "Personal protective equipment (PPE)")

    # Update Elasticsearch
    Investigation.import
    Product.import
  end
end
