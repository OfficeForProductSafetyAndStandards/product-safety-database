module Investigations
  class InvestigationProductsController < ApplicationController
    before_action :set_investigation
    before_action :set_investigation_product
    before_action :set_product

    def remove
      authorize @investigation, :update?
      authorize @investigation_product, :remove_product?

      @supporting_information = @product.supporting_information.select { |si| si.investigation == @investigation }
      render "supporting_information_warning" and return if @supporting_information.any?

      @remove_product_form = RemoveProductForm.new
    end

    # DELETE /cases/1/products
    def unlink
      authorize @investigation_product, :remove_product?
      @remove_product_form = RemoveProductForm.new(remove_product_params)
      return render(:remove) if @remove_product_form.invalid?

      if @remove_product_form.remove_product
        RemoveProductFromCase.call!(investigation: @investigation, investigation_product: @investigation_product, user: current_user, reason: @remove_product_form.reason)
        respond_to do |format|
          format.html do
            redirect_to_investigation_products_tab success: "The product record was removed from the case"
          end
          format.json { head :no_content }
        end
      else
        redirect_to_investigation_products_tab
      end
    end

    private

    def set_investigation
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      @investigation = investigation.decorate
    end

    def set_investigation_product
      @investigation_product = InvestigationProduct.find(params[:id])
    end

    def set_product
      @product = @investigation_product.product
    end

    def remove_product_params
      params.require(:investigation).permit(:remove_product, :reason)
    end

    def redirect_to_investigation_products_tab(flash = nil)
      redirect_to investigation_products_path(@investigation), flash:
    end
  end
end