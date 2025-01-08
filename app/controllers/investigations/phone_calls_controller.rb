class Investigations::PhoneCallsController < Investigations::BaseController
  before_action :set_investigation
  before_action :authorize_investigation_protected_details
  before_action :set_investigation_breadcrumbs

  def show
    @phone_call = @investigation_object.phone_calls.find(params[:id]).decorate
  end
end
