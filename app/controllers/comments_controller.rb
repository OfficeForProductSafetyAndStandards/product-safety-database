class CommentsController < ApplicationController
  before_action :set_investigation

  def new
    @investigation = @investigation.decorate
    @comment_form = CommentForm.new
  end

  def create
    @comment_form = CommentForm.new(comment_activity_params)

    if @comment_form.invalid?
      @investigation = @investigation.decorate
      return render(:new)
    end

    AddCommentToCase.call!(
      @comment_form.attributes.merge({
        investigation: @investigation,
        user: current_user
      })
    )

    redirect_to investigation_activity_path(@investigation), flash: { success: "The comment was successfully added" }
  end

private

  def set_investigation
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :comment?
  end

  def comment_activity_params
    params.require(:comment_form).permit(:body).tap do |p|
      p[:body] = ActionController::Base.helpers.sanitize(p[:body])
    end
  end
end
