class DeclarationController < ApplicationController
  skip_before_action :has_accepted_declaration
  skip_before_action :has_not_view_introduction
  before_action :set_errors

  def index
    session[:redirect_path] = params[:redirect_path]
  end

  def accept
    if params[:agree] != "checked"
      @error_list << :declaration_not_agreed_to
      return render :index
    end

    UserDeclarationService.accept_declaration(current_user)
    redirect_to after_sign_in_path_for(current_user)
  end

  def set_errors
    @error_list = []
  end
end
