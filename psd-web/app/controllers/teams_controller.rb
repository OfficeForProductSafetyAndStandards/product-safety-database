class TeamsController < ApplicationController
  def show
    @team = Team.find(params[:id]).decorate
    authorize @team
  end
end
