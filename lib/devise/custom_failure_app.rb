module Devise
  class CustomFailureApp < Devise::FailureApp
    def route(scope)
      # Return the host-less path rather than the full URL
      # to allow for different subdomains.
      :"new_#{scope}_session_path"
    end
  end
end
