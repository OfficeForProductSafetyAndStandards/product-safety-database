module InvestigationProducts
  class CustomsCodesController < ApplicationController
    def edit
      @investigation_product = InvestigationProduct.find(params[:investigation_product_id])
      authorize @investigation_product.investigation, :update?
    end

    def update
      @investigation_product = InvestigationProduct.find(params[:investigation_product_id])
      authorize @investigation_product.investigation, :update?

      if @investigation_product.customs_code.to_s == customs_code_params[:customs_code]
        return redirect_to investigation_path(@investigation_product.investigation)
      end

      result = ChangeCustomsCode.call!(investigation_product: @investigation_product, customs_code: customs_code_params[:customs_code], user: current_user)

      redirect_to investigation_path(@investigation_product.investigation), flash: result.changed ? { success: "The case information was updated" } : nil
    end

    def customs_code_params
      params.permit(:customs_code)
    end
  end
end
