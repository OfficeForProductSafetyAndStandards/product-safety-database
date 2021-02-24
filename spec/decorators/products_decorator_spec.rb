require "rails_helper"

RSpec.describe ProductsDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:decorated_products) { Product.all.decorate }

  let(:product_1) { create(:product, brand: "Brand 1", category: "Motor vehicles") }
  let(:product_2) { create(:product, brand: "Brand 2", category: "Clothing, textiles and fashion items") }

  describe "#to_csv" do
    it "returns a CSV string" do
      create(:allegation, products: [product_1, product_2])
      expect(decorated_products.to_csv).to eq("id,affected_units_status,authenticity,barcode,batch_number,brand,category,country_of_origin,created_at,customs_code,description,has_markings,markings,name,number_of_affected_units,product_code,subcategory,updated_at,webpage,when_placed_on_market,case_ids\n#{product_1.decorate.id},#{product_1.decorate.affected_units_status},#{product_1.decorate.authenticity},#{product_1.decorate.barcode},#{product_1.decorate.batch_number},#{product_1.decorate.brand},#{product_1.decorate.category},#{product_1.decorate.country_of_origin},#{product_1.decorate.created_at},#{product_1.decorate.customs_code},#{product_1.decorate.description},#{product_1.decorate.has_markings},#{product_1.decorate.markings},#{product_1.decorate.name},#{product_1.decorate.number_of_affected_units},#{product_1.decorate.product_code},#{product_1.decorate.subcategory},#{product_1.decorate.updated_at},#{product_1.decorate.webpage},#{product_1.decorate.when_placed_on_market},#{product_1.case_ids}\n#{product_2.decorate.id},#{product_2.decorate.affected_units_status},#{product_2.decorate.authenticity},#{product_2.decorate.barcode},#{product_2.decorate.batch_number},#{product_2.decorate.brand},\"#{product_2.decorate.category}\",#{product_2.decorate.country_of_origin},#{product_2.decorate.created_at},#{product_2.decorate.customs_code},#{product_2.decorate.description},#{product_2.decorate.has_markings},#{product_2.decorate.markings},#{product_2.decorate.name},#{product_2.decorate.number_of_affected_units},#{product_2.decorate.product_code},#{product_2.decorate.subcategory},#{product_2.decorate.updated_at},#{product_2.decorate.webpage},#{product_2.decorate.when_placed_on_market},#{product_2.case_ids}\n")
    end
  end
end
