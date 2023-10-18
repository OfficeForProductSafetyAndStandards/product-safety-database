class BulkProductsController < ApplicationController
  include CountriesHelper
  include UrlHelper
  include BreadcrumbHelper

  before_action :authorize_user

  def triage; end

private

  def authorize_user
    redirect_to "/403" if current_user && !current_user.can_bulk_upload_products?
  end
end
