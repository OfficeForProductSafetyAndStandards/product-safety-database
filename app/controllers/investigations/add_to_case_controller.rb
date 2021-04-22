module Investigations
  class AddToCaseController < ApplicationController
    def new
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
      authorize investigation, :update?
      @options_to_add = SupportingInformationTypeForm::MAIN_TYPES + { product: "Product", business: "Business" }
    end
  end
end
