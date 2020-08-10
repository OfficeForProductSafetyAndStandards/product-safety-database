class HelpController < ApplicationController
  skip_before_action :authenticate_user!,
                     :authorize_user,
                     :has_accepted_declaration,
                     :has_viewed_introduction,
                     :require_secondary_authentication

  def terms_and_conditions; end

  def privacy_notice; end

  def about; end

  def hide_nav?
    !(current_user.present? && current_user.has_accepted_declaration)
  end
end
