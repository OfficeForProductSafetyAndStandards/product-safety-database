module InvestigationProducts
  class UcrNumbersController < ApplicationController
    before_action :load_investigation_product

    def edit
      if @investigation_product.ucr_numbers.empty?
        @ucr_number = @investigation_product.ucr_numbers.build
      end
    end

    def update
      @investigation_product.assign_attributes(ucr_numbers_params)
      if @investigation_product.save
        redirect_to edit_investigation_product_ucr_numbers_path(@investigation_product), flash: { success: "UCR numbers updated" }
      else
        render :edit, status: 422
      end
    end

    def add_ucr_number
      @investigation_product.assign_attributes(ucr_numbers_params)
      if @investigation_product.save
        @ucr_number = @investigation_product.ucr_numbers.build
      end

      render :edit, status: 422
    end

  private

    def ucr_numbers_params
      params.require(:investigation_product).permit(ucr_numbers_attributes: [:id, :number, :_destroy])
    end

    def load_investigation_product
      @investigation_product = InvestigationProduct.find(params[:investigation_product_id])
      authorize @investigation_product.investigation, :update?
    end
  end
end
