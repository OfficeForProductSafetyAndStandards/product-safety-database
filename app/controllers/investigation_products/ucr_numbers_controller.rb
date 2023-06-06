module InvestigationProducts
  class UcrNumbersController < ApplicationController
    before_action :load_investigation_product

    def edit
      @ucr_number = @investigation_product.ucr_numbers.build
    end

    def update
      @ucr_numbers_form = UcrNumbersForm.new(ucr_numbers_params)

      if @ucr_numbers_form.valid?
        @investigation_product.assign_attributes(ucr_numbers_attributes: @ucr_numbers_form.ucr_numbers_attributes)
        @investigation_product.save!

        redirect_to edit_investigation_product_ucr_numbers_path(@investigation_product), flash: { success: "UCR numbers updated" }
      else
        render :edit
      end
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
