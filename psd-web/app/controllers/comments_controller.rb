class CommentsController < ApplicationController
  before_action :set_investigation

  def create
    @comment = @investigation.activities.new(comment_activity_params)
    @comment.investigation = @investigation
    @comment.source = UserSource.new(user: current_user)

    respond_to do |format|
      if @comment.save
        format.html do
          redirect_to investigation_activity_path(@investigation), flash: { success: "Comment was successfully added." }
        end
        format.json { render :show, status: :created, location: @comment }
      else
        format.html do
          render :new
        end
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def new
    @comment = @investigation.activities.new
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
