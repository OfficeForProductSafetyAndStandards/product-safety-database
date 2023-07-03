module Investigations
  class ImagesController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_investigation_non_protected_details
    before_action :set_investigation_breadcrumbs

    def index; end
  end
end
