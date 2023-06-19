module Investigations
  class ReferenceNumbersController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_investigation_updates
    before_action :set_investigation_breadcrumbs

    def edit; end

    def update
      if @investigation.complainant_reference == reference_number_params[:complainant_reference]
        return redirect_to investigation_path(@investigation)
      end

      ChangeCaseReferenceNumber.call!(investigation: @investigation, reference_number: reference_number_params[:complainant_reference], user: current_user)
      redirect_to investigation_path(@investigation), flash: { success: "The reference number was updated" }
    end

  private

    def reference_number_params
      params.require(:investigation).permit(:complainant_reference)
    end
  end
end
