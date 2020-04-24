# By default is using 'secondary_authentication' operation.
# To protect some actions with custom `secondary_authentication`,
# please override `user_id_for_secondary_authentication` and `current_operation` methods
# in such controller
#
# Only one action in controller can be protected by secondary authentication.
module SecondaryAuthenticationConcern
  extend ActiveSupport::Concern

  def require_secondary_authentication
    return unless Rails.configuration.secondary_authentication_enabled

    perform_secondary_authentication
  end

  def perform_secondary_authentication
    if user_id_for_secondary_authentication && !secondary_authentication_present_for_operation_and_user
      session[:secondary_authentication_redirect_to] = request.fullpath
      auth = SecondaryAuthentication.create(user_id: user_id_for_secondary_authentication, operation: current_operation)
      auth.generate_and_send_code
      redirect_to new_secondary_authentications_path(secondary_authentication_id: auth.id)
    end
  end

  # Use as `before_filter` in application_controller controller
  def ensure_secondary_authentication
    session[:secondary_authentication] ||= []
  end

  # used in application controller to cleanup old auths
  def cleanup_secondary_authentication
    session[:secondary_authentication].reject! do |auth_id|
      secondary_authentication = SecondaryAuthentication.find_by(id: auth_id)
      return true unless secondary_authentication

      if secondary_authentication.expired?
        secondary_authentication.delete
        true
      else
        false
      end
    end
  end

  def secondary_authentication_present_for_operation_and_user
    ids = session[:secondary_authentication]
    SecondaryAuthentication.where(id: ids).where(user_id: user_id_for_secondary_authentication).where(operation: current_operation).where(authenticated: true).present?
  end

  # can be overrided for actions which require
  # custom secondary authentication flow
  def user_id_for_secondary_authentication
    current_user.id
  end

  # can be overrided for actions which require
  # custom secondary authentication flow
  def current_operation
    SecondaryAuthentication::DEFAULT_OPERATION
  end
end
