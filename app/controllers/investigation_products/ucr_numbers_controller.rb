module InvestigationProducts
  class UcrNumbersController < ApplicationController
    before_action :load_investigation_product

    def edit
      if @investigation_product.ucr_numbers.empty?
        @ucr_number = @investigation_product.ucr_numbers.build
      end
    end

    def update
      service = ChangeUcrNumbers.call!(
        investigation_product: @investigation_product,
        user: current_user,
        ucr_numbers: ucr_numbers_params
      )

      if service.success
        redirect_to investigation_path(@investigation_product.investigation), flash: { success: "The case information was updated" }
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def add_ucr_number
      @investigation_product.assign_attributes(ucr_numbers_params)
      if @investigation_product.save
        @ucr_number = @investigation_product.ucr_numbers.build
      end

      render :edit, status: :unprocessable_entity
    end

  private

    def ucr_numbers_params
      params.require(:investigation_product).permit(ucr_numbers_attributes: %i[id number _destroy])
    end

    def load_investigation_product
      @investigation_product = InvestigationProduct.find(params[:investigation_product_id])
      authorize @investigation_product.investigation, :update?
    end
  end
end
