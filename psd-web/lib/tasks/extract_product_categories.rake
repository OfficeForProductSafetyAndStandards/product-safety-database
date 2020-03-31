task extract_investigation_product_categories: :environment do
  CSV.open("investigation-product-categories.csv", "wb") do |csv|
    Investigation.pluck(:id, :product_category).each do |investigation|
      csv << investigation
    end
  end
end


task import_investigation_product_categories: :environment do
  CSV.foreach("investigation-product-categories.csv") do |row|
    Investigation
      .where(id: row[0])
      .where(product_category: "Personal protective equipment (PPE)")
      .update_all(product_category: row[1])
  end

  # Update Elasticsearch
  Investigation.import
end
