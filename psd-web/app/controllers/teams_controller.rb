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

  def resend_invitation
    team = Team.find_by!(id: params[:id])
    email_address = params[:email_address]
    resend_invitation_to_user(email_address)
    redirect_to team, status: :see_other, flash: { success: "Invite sent to #{email_address}" }
  end

private

  def resend_invitation_to_user(email_address)
    User.resend_invite email_address, @team, root_url
  end

  def set_user_teams
    @teams = current_user.teams
  end

  def whitelisted_user
    if Rails.application.config.email_whitelist_enabled
      address = Mail::Address.new(@new_user.email_address)
      whitelisted_emails.include?(address.domain.downcase)
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
      if user.name.present?
        @new_user.errors.add(:email_address,
                             "#{@new_user.email_address} is already a member of #{@team.display_name}")
        nil
      else
        resend_invitation_to_user(user.email)
      end
    else
      invite_user(user)
    end
  end

  def invite_user(user)
    @team.add_user(user)
    email = NotifyMailer.user_added_to_team user.email,
                                            name: user.name,
                                            team_page_url: team_url(@team),
                                            team_name: @team.name,
                                            inviting_team_member_name: current_user.name
    email.deliver_later
  end

  def whitelisted_emails
    Rails.application.config.whitelisted_emails["email_domains"].map { |domain| domain.downcase.strip }
  end
end
