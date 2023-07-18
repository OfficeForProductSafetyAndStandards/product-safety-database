module Products
  class BarcodeLookupsController < ApplicationController
    before_action :find_barcode_lookup_product, only: %i[show confirm]

    def new
      @product_barcode_lookup_confirmation_form = ProductBarcodeLookupConfirmationForm.new
    end

    def show
      @product_barcode_lookup_confirmation_form = ProductBarcodeLookupConfirmationForm.new
    end

    def create

    end

    def confirm
      # SPIKE this should be a service here
      product = Product.create_from_barcode_lookup_product(@barcode_lookup_product.decorate)
      product.update!(
        barcode_lookup_product_id: @barcode_lookup_product.id,
        owning_team: current_user.team
      )

      redirect_to edit_product_path(product)
    end

  private

    def find_barcode_lookup_product
      # SPIKE - fix routes here, shouldn't be product_id but barcode_lookup_product_id
      @barcode_lookup_product = BarcodeLookupProduct.find(params[:product_id]).decorate
    end

  end
end
