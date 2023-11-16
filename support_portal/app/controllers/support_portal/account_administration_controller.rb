module SupportPortal
  class AccountAdministrationController < ApplicationController
    before_action :set_user, except: %i[index search search_results invite_user create_user]

    # GET /
    def index; end

    # GET /search
    def search; end

    # GET /search-results
    def search_results
      @search_query = params[:q].presence

      users = if @search_query
                ::User.not_deleted.joins(:team).where("users.name ILIKE ?", "%#{@search_query}%").or(::User.where("users.email ILIKE ?", "%#{@search_query}%"))
                  .select("users.id AS id, users.name AS name, users.email AS email, users.team_id AS team_id, teams.name AS team_name")
                  .merge(::User.order(name: :asc, created_at: :desc))
              else
                ::User.not_deleted.joins(:team).select("users.id AS id, users.name AS name, users.email AS email, users.team_id AS team_id, teams.name AS team_name")
                .merge(::User.order(name: :asc, created_at: :desc))
              end

      @records_count = users.size
      @pagy, @records = pagy(users)
    end

    # GET /:id
    def show; end

    # GET /:id/edit-name
    def edit_name; end

    # PATCH/PUT /:id/update-name
    def update_name
      existing_name = @user.name

      return redirect_to account_administration_path if existing_name == params[:user][:name]

      @user.assign_attributes(update_name_params)

      if @user.valid?(:change_name) && @user.update(update_name_params)
        redirect_to account_administration_path, notice: "The name has been updated from #{existing_name} to #{params[:user][:name]}."
      else
        render :edit_name
      end
    end

    # GET /:id/edit-email
    def edit_email; end

    # PATCH/PUT /:id/update-email
    def update_email
      existing_email = @user.email

      return redirect_to account_administration_path if existing_email == params[:user][:email]

      if @user.update(update_email_params)
        redirect_to account_administration_path, notice: "The email address has been updated from #{existing_email} to #{params[:user][:email]}."
      else
        render :edit_email
      end
    end

    # GET /:id/edit-mobile-number
    def edit_mobile_number; end

    # PATCH/PUT /:id/update-mobile-number
    def update_mobile_number
      existing_mobile_number = @user.mobile_number

      return redirect_to account_administration_path if existing_mobile_number == params[:user][:mobile_number]

      @user.assign_attributes(update_mobile_number_params)

      if @user.valid?(:change_mobile_number) && @user.update(update_mobile_number_params)
        redirect_to account_administration_path, notice: "The mobile number has been updated from #{existing_mobile_number} to #{params[:user][:mobile_number]}."
      else
        render :edit_mobile_number
      end
    end

    # GET /:id/edit-team-admin-role
    def edit_team_admin_role
      @current_team_admin = @user.roles.pluck(:name).include?("team_admin")
    end

    # PATCH/PUT /:id/update-team-admin-role
    def update_team_admin_role
      existing_team_admin_role = @user.roles.pluck(:name).include?("team_admin")
      new_team_admin_role = ActiveModel::Type::Boolean.new.cast(params[:user][:team_admin])

      return redirect_to account_administration_path if existing_team_admin_role == new_team_admin_role

      if new_team_admin_role
        @user.roles.create!(name: "team_admin")
      else
        @user.roles.find_by(name: "team_admin").destroy!
      end

      redirect_to account_administration_path, notice: "The team admin role has been #{new_team_admin_role ? 'added' : 'removed'}."
    end

    # GET /:id/remove-user
    def remove_user; end

    # DELETE /:id/delete-user
    def delete_user
      ::DeleteUser.call!(user: @user, deleted_by: current_user)
      redirect_to account_administration_index_path, notice: "The user account has been deleted."
    end

    # GET /invite-user
    def invite_user
      @invite_user_form = InviteUserForm.new
    end

    # PATCH/PUT /create-user
    def create_user
      @invite_user_form = InviteUserForm.new(invite_user_params)

      if @invite_user_form.valid?
        ::InviteUserToTeam.call!(invite_user_params.merge(team: ::Team.find(invite_user_params[:team_id]), inviting_user: current_user))
        redirect_to invite_user_account_administration_index_path, notice: "New user account invitation has been sent."
      else
        render :invite_user
      end
    end

  private

    def set_user
      @user = ::User.not_deleted.joins(:team).left_joins(:roles).find(params[:id])
    end

    def update_name_params
      params.require(:user).permit(:name)
    end

    def update_email_params
      params.require(:user).permit(:email)
    end

    def update_mobile_number_params
      params.require(:user).permit(:mobile_number)
    end

    def update_team_admin_role_params
      params.require(:user).permit(:team_admin)
    end

    def invite_user_params
      params.require(:invite_user_form).permit(:name, :email, :team_id)
    end
  end
end
