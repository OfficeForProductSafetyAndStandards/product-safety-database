module SecondaryAuthenticationConcern
  extend ActiveSupport::Concern

  # included do
  #   before_action :ensure_secondary_authentication
  #   before_action :cleanup_secondary_authentication
  # end

  # To be called by controller that require secondary authentication
  # Such controller should define `current_operation` and `user_id_for_operation`
  def require_secondary_authentication
    binding.pry
    unless secondary_authentication_present_for_operation_and_user
      session[:secondary_authentication_redirect_to] = request.fullpath
      auth = SecondaryAuthentication.create(user_id: user_id, operation: current_operation)
      auth.generate_and_send_code
      redirect_to new_secondary_authentications_path(secondary_authentication_id: auth.id)
    end
  end

  # Use as `before_filter` in application_controller controller
  def ensure_secondary_authentication
    session[:secondary_authentication] = [] unless session[:secondary_authentication].present?
  end

  # used in application controller to cleanup old auths
  def cleanup_secondary_authentication
    session[:secondary_authentication].reject! do |auth_id|
      unless SecondaryAuthentication.find_by(id: auth_id)
        return true
      end
      if SecondaryAuthentication.find_by(auth_id).expired?
        SecondaryAuthentication.find(auth_id).delete
        true
      else
        false
      end
    end
  end

  def secondary_authentication_present_for_operation_and_user
    ids = session[:secondary_authentication]
    SecondaryAuthentication.where(id: ids).where(user_id: user_id).where(operation: current_operation).where(authenticated: true).present?
  end

  def user_id
    user_id_for_operation || current_user.id
  end
end
