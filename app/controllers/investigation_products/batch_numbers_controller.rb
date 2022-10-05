module InvestigationProducts
  class BatchNumbersController < ApplicationController
    def edit
      @investigation_product = InvestigationProduct.find(params[:investigation_product_id])
      authorize @investigation_product.investigation, :update?
    end

    def update
      @investigation_product = InvestigationProduct.find(params[:investigation_product_id])
      authorize @investigation_product.investigation, :update?

      if @investigation_product.batch_number.to_s == batch_number_params[:batch_number]
        return redirect_to investigation_path(@investigation_product.investigation)
      end

      ChangeBatchNumber.call!(investigation_product: @investigation_product, batch_number: batch_number_params[:batch_number], user: current_user)
      redirect_to investigation_path(@investigation_product.investigation), flash: { success: "The case information was updated" }
    end

    def batch_number_params
      params.permit(:batch_number)
    end
  end
end
