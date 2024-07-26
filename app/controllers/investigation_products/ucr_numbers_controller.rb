module InvestigationProducts
  class UcrNumbersController < ApplicationController
    before_action :load_investigation_product

    def edit
      @ucr_number = @investigation_product.ucr_numbers.build
    end

    def update
      service = ChangeUcrNumbers.call(
        investigation_product: @investigation_product,
        user: current_user,
        ucr_numbers: ucr_numbers_params
      )
      if service.success?
        ahoy.track "Updated UCR numbers", { notification_id: @investigation_product.investigation.id }
        redirect_to investigation_path(@investigation_product.investigation, anchor: "case_ucr_numbers_#{@investigation_product.id}"), flash: { success: "The UCR numbers were updated" }
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # TODO: needs to be reviewed during refactoring
    # def add_ucr_number
    #   @investigation_product.assign_attributes(ucr_numbers_params)
    #   if @investigation_product.save
    #     @ucr_number = @investigation_product.ucr_numbers.build
    #   end
    #
    #   render :edit, status: :unprocessable_entity
    # end
    #
    # def destroy
    #   @ucr_number = @investigation_product.ucr_numbers.find(params[:id])
    #   @ucr_number.destroy!
    #   ahoy.track "Deleted UCR number", { notification_id: @investigation_product.investigation.id }
    #   redirect_to investigation_path(@investigation_product.investigation, anchor: "case_ucr_numbers_#{@investigation_product.id}"), flash: { success: "The UCR numbers were deleted" }
    # end

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
