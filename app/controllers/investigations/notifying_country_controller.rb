module Investigations
  class NotifyingCountryController < ApplicationController
    def edit
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      authorize @investigation, :update?
      @notifying_country_form = NotifyingCountryForm.new
    end

    def update
    end
  end
end
