require "rails_helper"
require "swagger_helper"

RSpec.describe "API Products Controller", type: :request do
  let(:user) { create(:user, :activated, :with_api_token, has_viewed_introduction: true, team: user_team) }
  let(:user_team) { create(:team) }
  let!(:product) { create(:product, product_code: product_code_asin) }
  let(:product_code_asin) { 'B07K1RZWMC' }

  path "/api/v1/products/{id}" do
    get "Retrieves a Product" do
      description "Retrieves a Product's detail by ID"
      tags "Products"
      produces "application/json"
      security [bearer: []]
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :id, in: :path, type: :string

      response "200", "Product found" do
        schema '$ref' => '#/components/schemas/product_object'

        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }

        let(:id) { create(:product, country_of_origin: 'country:GB').id }

        after do |example|
          content = example.metadata[:response][:content] || {}
          example_spec = {
            "application/json"=>{
              examples: {
                test_example: {
                  value: JSON.parse(response.body, symbolize_names: true)
                }
              }
            }
          }
          example.metadata[:response][:content] = content.deep_merge(example_spec)
        end

        run_test! do |response|

        end
      end

      response "404", "Product not found" do
        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }
        let(:id) { "invalid" }
        run_test!
      end

      response "401", "Unauthorised user" do
        let(:Authorization) { "Authorization 0000" }
        let(:id) { "invalid" }
        run_test!
      end
    end
  end

  path "/api/v1/products" do
    get "Search for a Product" do
      description %{
Search for a Product

* The search `q` query searches for Products in PSD with the same code as is used in the application. It fuzzy matches based on name, description, brand, PSD ID, and product_code.
* The `sort_by` parameter can be used to sort the results. The default is `relevant` which returns the most relevant first. The `sort_dir` parameter can be used to sort the results in ascending `asc` or descending `desc` order. The default is descending.
* The `category` parameter can be used to filter the results by category. If given, only products in this category will be returned.
* The `page` parameter can be used to paginate the results. By default, 20 results are returned per page.
}
      tags "Products"
      produces "application/json"
      security [bearer: []]
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :q, in: :query, type: :string, description: "Search query. Searches based on name, description, brand, PSD ID, and product_code"
      parameter name: :sort_by, in: :query, required: false, type: :string, description: "Sort by parameter. Choose name, created_at, updated_at, or relevant. Default is relevant"
      parameter name: :sort_dir, in: :query, required: false, type: :string, description: "Sort direction. Choose asc or desc. Default is desc"
      parameter name: :category, in: :query, required: false, type: :string, description: "Category of the product. If given, only products in this category will be returned"

      parameter name: :page, required: false, in: :query, type: :integer, description: "Page number"

      response "200", "Search results returned" do
        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }
        let(:q) { product_code_asin }

        run_test! do |response|
          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body, symbolize_names: true)
          expect(json[:products].size).to eq(1)
          expect(json[:products].first[:product_code]).to eq(product_code_asin)
        end
      end
    end
  end

  path "/api/v1/products/named_parameter_search" do
    get "Named parameter search for a Product" do
      description %{
Search for a Product using named parameters.

* The `name` parameter fuzzy searches based on `name`
* The `ID`, `barcode`, and `product_code` parameters search based on exact matches
* Providing each parameter will perform an AND search, i.e. all parameters must match
* For PSD ID, please issue without `psd-` (e.g. for `psd-1234` use `1234`).
* `product_code` can contain the ASIN, EAN, or UPC codes for a given product.
* The `sort_by` parameter can be used to sort the results. The default is `relevant` which returns the most relevant first. The `sort_dir` parameter can be used to sort the results in ascending `asc` or descending `desc` order. The default is descending.
* The `category` parameter can be used to filter the results by category. If given, only products in this category will be returned.
* The `page` parameter can be used to paginate the results. By default, 20 results are returned per page.
}
      tags "Products"
      produces "application/json"
      security [bearer: []]
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :name, in: :query, type: :string, description: "Fuzzy searches based on product name", required: false
      parameter name: :id, in: :query, type: :string, description: "Search based on exact match of PSD ID. Please issue without `psd-` (e.g. for `psd-1234` use `1234`)", required: false
      parameter name: :barcode, in: :query, type: :string, description: "Search based on exact match of barcode", required: false
      parameter name: :product_code, in: :query, type: :string, description: "Search based on fuzzy match of product_code. Can contain the ASIN, EAN, or UPC codes for a given product", required: false

      parameter name: :sort_by, in: :query, required: false, type: :string, description: "Sort by parameter. Choose name, created_at, updated_at, or relevant. Default is relevant"
      parameter name: :sort_dir, in: :query, required: false, type: :string, description: "Sort direction. Choose asc or desc. Default is desc"
      parameter name: :category, in: :query, required: false, type: :string, description: "Category of the product. If given, only products in this category will be returned"

      parameter name: :page, required: false, in: :query, type: :integer, description: "Page number"

      response "200", "Search results returned" do
        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }

        let!(:product) { create(:product, barcode: barcode) }
        let(:barcode) { '12345678' }

        run_test! do |response|
          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body, symbolize_names: true)
          expect(json[:products].size).to eq(1)
          expect(json[:products].first[:name]).to eq(product.name)
        end
      end
    end
  end

  path "/api/v1/products" do
    post "Creates a Product" do
      description "Creates a Product in PSD"
      tags "Products"
      security [bearer: []]
      parameter name: :Authorization, in: :header, type: :string
      let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }

      consumes 'application/json'

      request_body_example value: {
        product: {
          name: 'Super Vac 2020',
          category: 'Electrical appliances and equipment',
          subcategory: 'Vacuum cleaners',
          country_of_origin: 'country:GB',
          when_placed_on_market: 'on_or_after_2021',
          authenticity: 'genuine',
          has_markings: 'markings_no'
        }
      }, name: 'product', summary: "An sample product"

      parameter name: :product, in: :body, schema: { '$ref' => '#/components/schemas/new_product' }

      response "201", "Product created" do
        schema '$ref' => '#/components/schemas/product_object'
        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }
        let(:product) do
          {
            name: 'Super Vac 2020',
            brand: 'SuperDuper',
            category: 'Electrical appliances and equipment',
            subcategory: 'Vacuum cleaners',
            country_of_origin: 'country:GB',
            when_placed_on_market: 'on_or_after_2021',
            authenticity: 'genuine',
            has_markings: 'markings_no'
          }
        end

        run_test! do |response|
          json = JSON.parse(response.body, symbolize_names: true)

          expect(json[:id]).to be_present
          expect(json[:name]).to eq('Super Vac 2020')
          expect(json[:category]).to eq('Electrical appliances and equipment')
          expect(json[:subcategory]).to eq('Vacuum cleaners')
          expect(json[:country_of_origin]).to eq('country:GB')
        end
      end

      response "406", "Product not valid" do
        let(:Authorization) { "Authorization #{user.api_tokens.first&.token}" }
        let(:product) do
          {
            subcategory: 'Vacuum cleaners',
          }
        end
        run_test! do |response|
          json = JSON.parse(response.body, symbolize_names: true)

          expect(json[:errors]).to be_present
        end
      end

      response "401", "Unauthorised user" do
        let(:Authorization) { "Authorization 0000" }
        let(:id) { "invalid" }
        run_test!
      end
    end
  end

end
