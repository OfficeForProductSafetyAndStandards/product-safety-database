require "test_helper"

class Investigations::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:southampton)
    @investigation = load_case(:one)
    @investigation.edit_access_collaborations.create!(
      collaborator: teams(:southampton_team),
      include_message: false,
      added_by_user: users(:southampton)
    )
    @investigation.creator_user = users(:southampton)
    @product = products(:iphone)
    @product.source = sources(:product_iphone)
  end

  test "should get new" do
    get new_investigation_product_url(@investigation)
    assert_response :success
  end

  test "should create and link product" do
    assert_difference ["InvestigationProduct.count", "Product.count"] do
      post investigation_products_url(@investigation),
           params: {
             product: {
               name: @product.name,
               batch_number: @product.batch_number,
               product_type: @product.product_type,
               category: @product.category,
               webpage: @product.webpage,
               description: @product.description,
               product_code: @product.product_code,
             }
           }
    end
    assert_redirected_to investigation_products_path(@investigation)
  end

  test "should not create product if name is missing" do
    assert_no_difference ["InvestigationProduct.count", "Product.count"] do
      post investigation_products_url(@investigation),
           params: {
             product: {
               name: "",
               batch_number: @product.batch_number,
               product_type: @product.product_type,
               category: @product.category,
               description: @product.description,
               webpage: @product.webpage,
               product_code: @product.product_code
             }
           }
    end
  end

  test "should link product and investigation" do
    assert_difference "InvestigationProduct.count" do
      put link_investigation_product_url(@investigation, @product)
    end
    assert_redirected_to investigation_products_path(@investigation)
  end

  test "should unlink product and investigation" do
    @investigation.products << @product
    assert_difference "InvestigationProduct.count", -1 do
      delete unlink_investigation_product_url(@investigation, @product)
    end

    assert_redirected_to investigation_products_path(@investigation)
  end
end
