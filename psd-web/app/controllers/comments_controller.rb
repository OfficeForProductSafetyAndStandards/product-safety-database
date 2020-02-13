class CommentsController < ApplicationController
  before_action :set_investigation

  def create
    activity = @investigation.activities.new(comment_activity_params.merge(investigation: @investigation))
    activity.source = UserSource.new(user: current_user)

    respond_to do |format|
      if activity.save
        format.html do
          redirect_to investigation_url(@investigation), flash: { success: "Comment was successfully added." }
        end
        format.json { render :show, status: :created, location: @activity }
      else
        format.html do
          redirect_to new_investigation_activity_comment_url(@investigation), flash: { warning: "Comment was not successfully added." }
        end
        format.json { render json: activity.errors, status: :unprocessable_entity }
      end
    end
  end

private

  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :show?
    @investigation = investigation.decorate
  end

  def comment_activity_params
    params.require(:comment_activity).permit(:body).tap do |p|
      p[:body] = ActionController::Base.helpers.sanitize(p[:body])
    end
  end
end
