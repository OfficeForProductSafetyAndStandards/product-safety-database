class Investigations::EmailsController < Investigations::BaseController
  before_action :set_investigation
  before_action :authorize_investigation_protected_details
  before_action :set_investigation_breadcrumbs

  def show
    @email = @investigation_object.emails.find(params[:id]).decorate
  end
end
