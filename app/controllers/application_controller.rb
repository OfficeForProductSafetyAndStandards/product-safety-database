class ApplicationController < ActionController::Base
  include Pundit
  include CacheConcern
  include HttpAuthConcern
  include SentryConfigurationConcern
  include SecondaryAuthenticationConcern

  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :set_current_user
  before_action :ensure_secondary_authentication
  before_action :require_secondary_authentication
  before_action :set_sentry_context
  before_action :authorize_user
  before_action :has_accepted_declaration
  before_action :has_viewed_introduction
  before_action :set_cache_headers

  helper_method :nav_items, :secondary_nav_items, :previous_search_params, :current_user, :root_path_for

  rescue_from Wicked::Wizard::InvalidStepError, with: :render_404_page

  def set_current_user
    return unless user_signed_in?

    User.current = current_user
  end

  def authorize_user
    return unless user_signed_in?
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
    unless current_user.is_opss?
      items.push text: "Home", href: authenticated_opss_root_path, active: params[:controller] == "homepage"
    end
    items.push text: "Cases", href: investigations_path(previous_search_params), active: params[:controller].match?(/investigations|searches|collaborators/)
    items.push text: "Businesses", href: businesses_path, active: params[:controller].start_with?("businesses")
    items.push text: "Products", href: products_path, active: params[:controller].start_with?("products")
    items.push text: "Your team", href: team_path(current_user.team), active: params[:controller].start_with?("teams"), right: true
    items
  end

  def previous_search_params
    # No clear way to only replace search params, as they are seperate from each other and not easily identifiable.
    # This list will have to be updated when new search filters are added.
    if session[:previous_search_params].present?
      s = session[:previous_search_params]
      {
        case_owner_is_me: s[:case_owner_is_me],
        case_owner_is_my_team: s[:case_owner_is_my_team],
        case_owner_is_someone_else: s[:case_owner_is_someone_else],
        case_owner_is_someone_else_id: s[:case_owner_is_someone_else_id],
        created_by: s[:created_by],
        teams_with_access: s[:teams_with_access],
        allegation: s[:allegation],
        enquiry: s[:enquiry],
        project: s[:project],
        status_open: s[:status_open],
        status_closed: s[:status_closed],
        sort_by: s[:sort_by],
        coronavirus_related_only: s[:coronavirus_related_only],
        serious_and_high_risk_level_only: s[:serious_and_high_risk_level_only]
      }
    else
      {}
    end
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

  def root_path_for(resource)
    resource.is_opss? ? authenticated_opss_root_path : authenticated_msa_root_path
  end

private

  def render_404_page
    render "errors/not_found", status: :not_found
  end
end
