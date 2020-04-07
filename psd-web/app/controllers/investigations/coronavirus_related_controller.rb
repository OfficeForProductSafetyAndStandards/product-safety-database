module Investigations
  class CoronavirusRelatedController < ApplicationController

    def show
      @investigation = Investigation.find_by(pretty_id: params.require(:investigation_pretty_id)).decorate
    end
  end
end
