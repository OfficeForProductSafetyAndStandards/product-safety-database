class TeamsController < ApplicationController
  before_action :set_user_teams, only: :index
  before_action :set_team, only: %i[show invite_to]
  before_action :set_new_user, only: :invite_to

  # GET /teams, GET /my-teams
  def index; end

  def show; end

  # GET /teams/:id/invite, PUT /teams/:id/invite
  def invite_to
    return unless request.put? && @new_user.valid?

    existing_user = User.find_by email: @new_user.email_address
    if existing_user
      invite_existing_user_if_able existing_user
    elsif whitelisted_user
      User.create_and_send_invite @new_user.email_address, @team, root_url
    else
      @new_user.errors.add(:email_address, :email_not_in_whitelist)
    end

    if @new_user.errors.empty?
      redirect_to @team, status: :see_other, flash: { success: "Invite sent to #{@new_user.email_address}" }
    else
      render :invite_to, status: :bad_request
    end
  end

private

  def set_user_teams
    @teams = User.current.teams
  end

  def whitelisted_user
    if ENV["EMAIL_WHITELIST_ENABLED"] == "true"
      address = Mail::Address.new(@new_user.email_address)
      whitelisted_emails.include?(address.domain)
    else
      true
    end
  end

  def set_team
    @team = Team.find(params[:id])
    authorize @team
  end

  def set_new_user
    @new_user = NewUser.new params[:new_user]&.permit(:email_address)
  end

  def invite_existing_user_if_able(user)
    if user.organisation.present? && user.organisation != @team.organisation
      @new_user.errors.add(:email_address, :member_of_another_organisation)
      return
    end
    if @team.users.include? user
      @new_user.errors.add(:email_address,
                           "#{@new_user.email_address} is already a member of #{@team.display_name}")
      return
    end
    invite_user user
  end

  def invite_user(user)
    @team.add_user(user)
    email = NotifyMailer.user_added_to_team user.email,
                                            name: user.name,
                                            team_page_url: team_url(@team),
                                            team_name: @team.name,
                                            inviting_team_member_name: User.current.name
    email.deliver_later
  end

  def whitelisted_emails
    Rails.application.config.whitelisted_emails["email_domains"]
  end
end
