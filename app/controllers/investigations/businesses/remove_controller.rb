module Investigations
  module Businesses
    class RemoveController < ApplicationController
      def show
        @investigation        = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
        @business             = @investigation.businesses.find(params[:business_id])
        @remove_business_form = RemoveBusinessForm.new
      end

      def create
        investigation         = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
        @business             = investigation.businesses.find(params[:business_id])
        @remove_business_form = RemoveBusinessForm.new(remove_business_params)

        if @remove_business_form.invalid?
          @investigation = investigation.decorate
          return render :show
        end

        result = RemoveBusinessFromCase.call!(
          investigation: investigation,
          business: @business,
          user: current_user
        )

        if result.success?
          redirect_to investigation_businesses_path(investigation, @business), flash: { success: t(".business_successfully_deleted") }
        else
          @investigation = investigation.decorate
          render :show
        end
      end

    private

      def remove_business_params
        params.require(:remove_business_form).permit(:remove, :reason)
      end
    end
  end
end
