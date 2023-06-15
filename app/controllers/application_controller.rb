class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include CacheConcern
  include HttpAuthConcern
  include SentryConfigurationConcern
  include SecondaryAuthenticationConcern
  include CookiesConcern
  include BreadcrumbHelper

  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit
  before_action :check_current_user_status
  before_action :set_user_last_activity_time
  before_action :ensure_secondary_authentication
  before_action :require_secondary_authentication
  before_action :set_sentry_context
  before_action :has_accepted_declaration
  before_action :has_viewed_introduction
  before_action :set_cache_headers

  before_action :set_home_breadcrumb

  helper_method :nav_items, :secondary_nav_items, :current_user, :root_path_for

  rescue_from Wicked::Wizard::InvalidStepError, with: :render_404_page

  def check_current_user_status
    return unless user_signed_in?

    if current_user.access_locked? || current_user.deleted?
      sign_out current_user
      redirect_to "/"
    end
  end

  def set_user_last_activity_time
    return unless user_signed_in?

    current_user.update_last_activity_time!
  end

  def has_accepted_declaration
    return unless user_signed_in?

    unless current_user.has_accepted_declaration?
      stored_location_for(current_user)
      redirect_to declaration_index_path
    end
  end

  def hide_nav?
    false
  end

  def nav_items
    return nil if hide_nav? || !current_user # On some pages we don't want to show the main navigation

    items = []
    items.push text: "Home", href: authenticated_root_path, active: params[:controller] == "homepage"
    items.push text: "Cases", href: your_cases_investigations_path, active: highlight_cases?
    items.push text: "Businesses", href: your_businesses_path, active: highlight_businesses?
    items.push text: "Products", href: your_products_path, active: highlight_products?
    items.push text: "Your team", href: team_path(current_user.team), active: params[:controller].start_with?("teams"), right: true
    items
  end

  def secondary_nav_items
    items = []
    if user_signed_in?
      items.push text: "Your account", href: account_path
      items.push text: "Sign out", href: destroy_user_session_path
    else
      items.push text: "Sign in", href: new_user_session_path
    end
    items
  end

  def has_viewed_introduction
    return unless user_signed_in?
    return if current_user.is_opss?

    unless current_user.has_viewed_introduction
      stored_location_for(current_user)
      redirect_to introduction_overview_path
    end
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path_for(resource)
  end

  def after_sign_out_path_for(*)
    unauthenticated_root_path
  end

  def root_path_for(_resource)
    authenticated_root_path
  end

protected

  def set_business_breadcrumbs
    breadcrumb "businesses.label", :businesses_path
    breadcrumb breadcrumb_business_label, breadcrumb_business_path
    breadcrumb @business.trading_name, business_path(@business) if @business&.persisted?
  end

private

  def set_home_breadcrumb
    breadcrumb "Home", authenticated_root_path
  end

  def render_404_page
    render "errors/not_found", status: :not_found
  end

  def highlight_businesses?
    return true if params[:controller].start_with?("businesses")
    return true if params[:controller] == "documents" && params[:business_id]
  end

  def highlight_products?
    return true if params[:controller].start_with?("product")
    return true if %w[documents document_uploads].include?(params[:controller]) && params[:product_id]
  end

  def highlight_cases?
    return true if params[:controller].match?(/investigations|searches|collaborators|comments/)
    return true if params[:controller] == "documents" && params[:investigation_pretty_id]
  end
end
