module InvestigationProducts
  class BatchNumbersController < Investigations::BaseController
    before_action :set_investigation_product
    before_action :authorize_investigation_updates
    before_action :set_investigation_breadcrumbs

    def edit; end

    def update
      if @investigation_product.batch_number.to_s == batch_number_params[:batch_number]
        return redirect_to investigation_path(@investigation_product.investigation)
      end

      ChangeBatchNumber.call!(investigation_product: @investigation_product, batch_number: batch_number_params[:batch_number], user: current_user)
      ahoy.track "Updated batch number", { notification_id: @investigation.id }
      redirect_to investigation_path(@investigation_product.investigation, anchor: "case_batch_numbers_#{@investigation_product.id}"), flash: { success: "The notification information was updated" }
    end

  private

    def set_investigation_product
      @investigation_product = InvestigationProduct.find(params[:investigation_product_id])
      @investigation = @investigation_product.investigation.decorate
    end

    def batch_number_params
      params.permit(:batch_number)
    end
  end
end
