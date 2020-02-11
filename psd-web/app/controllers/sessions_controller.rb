class SessionsController < Devise::SessionsController
  skip_before_action :has_accepted_declaration
  skip_before_action :has_view_introduction
end
