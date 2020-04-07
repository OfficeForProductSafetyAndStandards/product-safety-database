module Investigations
  class CoronavirusRelatedController < ApplicationController
    def show
      @investigation = Investigation.find_by(pretty_id: params.require(:investigation_pretty_id)).decorate
    end

    def update
      investigation = Investigation.find_by(pretty_id: params.require(:investigation_pretty_id))
      investigation.update!(params.require(:investigation).permit(:coronavirus_related))

      redirect_to investigation_path(investigation), success: "#{investigation.case_type.titleize} was successfully updated."
    end
  end
end
