class SessionsController < ApplicationController
  skip_before_action :has_accepted_declaration
  skip_before_action :has_viewed_introduction

  skip_before_action :authenticate_user!, :authorize_user, :set_current_user, :set_raven_context

  def sign_in; end

  def two_factor; end

  def reset_password; end

  def text_not_received; end

  def text_not_received_account_creation; end

  def check_your_email; end

  def new_password; end

  def link_expired; end

  def invite_expired; end

  def create_account; end

end
