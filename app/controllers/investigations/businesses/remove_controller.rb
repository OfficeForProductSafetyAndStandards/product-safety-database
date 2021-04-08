module Investigations
  module Businesses
    class RemoveController < ApplicationController
      def show
        @investigation         = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
        @business             = @investigation.businesses.find(params[:business_id])
        @remove_business_form = RemoveBusinessForm.new
      end

      def create
        @investigation        = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
        investigation_business = @investigation.investigation_businesses.find_by!(business_id: params[:business_id])
        @business             = investigation_business.business
        @remove_business_form = RemoveBusinessForm.new(remove_business_params)
        # byebug
        return render :show if @remove_business_form.invalid?

        result = RemoveBusinessFromCase.call!(
          investigation: @investigation,
          investigation_business: investigation_business,
          user: current_user
        )

        if result.success?
          redirect_to investigation_businesses_path(@investigation, @business), success: "Business was successfully removed."
        else
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
