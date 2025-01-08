class FlagAsCounterfeitProducts < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      reversible do |dir|
        dir.up do
          execute <<~SQL
              UPDATE products SET authenticity = 'counterfeit' WHERE id IN (
                   SELECT id FROM (
                                 SELECT id AS id , CONCAT(batch_number, ' ', category, ' ', description, ' ', product_code, ' ', name, ' ', brand) AS search FROM products
                          ) AS joined
                   WHERE search ILIKE '%counterfeit%'
            )
          SQL
        end
      end
    end
  end
end
