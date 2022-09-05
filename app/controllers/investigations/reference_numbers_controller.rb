module Investigations
  class ReferenceNumbersController < ApplicationController
    def edit
      @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
      authorize @investigation, :update?
    end

    def update
      @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
      authorize @investigation, :update?

      if @investigation.complainant_reference == reference_number_params[:complainant_reference]
        redirect_to investigation_path(@investigation)
      else
        @investigation.update!(reference_number_params)
        redirect_to investigation_path(@investigation), flash: { success: "Reference number was successfully updated" }
      end
    end

  private

    def reference_number_params
      params.require(:investigation).permit(:complainant_reference)
    end
  end
end
