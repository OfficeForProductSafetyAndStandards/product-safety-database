class ApplicationController < ActionController::Base
  include Pundit
  include CacheConcern
  include HttpAuthConcern
  include RavenConfigurationConcern
  include SecondaryAuthenticationConcern

  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :set_current_user
  before_action :ensure_secondary_authentication
  before_action :require_secondary_authentication
  before_action :set_raven_context
  before_action :authorize_user
  before_action :has_accepted_declaration
  before_action :has_viewed_introduction
  before_action :set_cache_headers

  helper_method :nav_items, :secondary_nav_items, :previous_search_params, :current_user

  rescue_from Wicked::Wizard::InvalidStepError, with: :render_404_page

  def set_current_user
    return unless user_signed_in?

    User.current = current_user
  end

  def authorize_user
    return unless user_signed_in?

    raise Pundit::NotAuthorizedError unless current_user.is_psd_user?
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
      items.push text: "Home", href: root_path, active: params[:controller] == "homepage"
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
        case_owner_is_someone_else: s[:case_owner_is_someone_else],
        case_owner_is_someone_else_id: s[:case_owner_is_someone_else_id],
        case_owner_is_team_0: s[:case_owner_is_team_0],
        created_by_me: s[:created_by_me],
        created_by_someone_else: s[:created_by_someone_else],
        created_by_someone_else_id: s[:created_by_someone_else_id],
        created_by_team_0: s[:created_by_team_0],
        allegation: s[:allegation],
        enquiry: s[:enquiry],
        project: s[:project],
        status_open: s[:status_open],
        sort_by: s[:sort_by],
        status_closed: s[:status_closed],
        coronavirus_related_only: s[:coronavirus_related_only]
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
    stored_location_for(resource) || root_path
  end

  def after_sign_out_path_for(*)
    root_path
  end

private

  def render_404_page
    render "errors/not_found", status: :not_found
  end
end
