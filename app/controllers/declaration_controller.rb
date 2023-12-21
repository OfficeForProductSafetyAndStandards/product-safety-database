class DeclarationController < ApplicationController
  skip_before_action :has_accepted_declaration
  skip_before_action :has_viewed_introduction

  def index
    session[:redirect_path] = params[:redirect_path]
    @declaration_form = DeclarationForm.new
  end

  def accept
    @declaration_form = DeclarationForm.new(declaration_params)

    if @declaration_form.valid?
      UserDeclarationService.accept_declaration(current_user)
      redirect_to after_sign_in_path_for(current_user)
    else
      render :index
    end
  end

private

  def declaration_params
    params.require(:declaration_form).permit(:agree)
  end
end
