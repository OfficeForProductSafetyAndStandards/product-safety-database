json.extract! product,
              :id,
              :product_code,
              :name,
              :subcategory,
              :category,
              :webpage,
              :description,
              :added_by_user,
              :batch_number,
              :country_of_origin,
              :created_at,
              :updated_at
json.url product_url(product, format: :json)
