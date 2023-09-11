module InvestigationProducts
  class CustomsCodesController < Investigations::BaseController
    before_action :set_investigation_product
    before_action :authorize_investigation_updates
    before_action :set_investigation_breadcrumbs

    def edit; end

    def update
      if @investigation_product.customs_code.to_s == customs_code_params[:customs_code]
        return redirect_to investigation_path(@investigation_product.investigation)
      end

      result = ChangeCustomsCode.call!(investigation_product: @investigation_product, customs_code: customs_code_params[:customs_code], user: current_user)

      redirect_to investigation_path(@investigation_product.investigation, anchor: "case_customs_codes_#{@investigation_product.id}"), flash: result.changed ? { success: "The case information was updated" } : nil
    end

  private

    def set_investigation_product
      @investigation_product = InvestigationProduct.find(params[:investigation_product_id])
      @investigation = @investigation_product.investigation.decorate
    end

    def customs_code_params
      params.permit(:customs_code)
    end
  end
end
