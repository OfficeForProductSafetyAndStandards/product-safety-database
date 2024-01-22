json.id product.id
json.name product.name
json.brand product.brand
json.product_code product.product_code
json.barcode product.barcode
json.category product.category
json.subcategory product.subcategory
json.description product.description
json.country_of_origin product.country_of_origin
json.webpage product.webpage
json.owning_team do
  json.name product.owning_team&.name
  json.email product.owning_team&.email
end

json.product_images product.virus_free_images.each do |image|
  json.url url_for(image)
end
