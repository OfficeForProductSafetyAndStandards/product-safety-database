class CommentsController < Investigations::BaseController
  before_action :set_investigation
  before_action :authorize_investigation_commenting
  before_action :set_investigation_breadcrumbs

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

    AddCommentToNotification.call!(
      @comment_form.attributes.merge({
        notification: @investigation,
        user: current_user
      })
    )

    if current_user.can_use_notification_task_list?
      redirect_to notification_path(@investigation)
    else
      redirect_to investigation_activity_path(@investigation), flash: { success: "The comment was successfully added" }
    end
  end

private

  def authorize_investigation_commenting
    authorize @investigation, :comment?
  end

  def comment_activity_params
    params.require(:comment_form).permit(:body).tap do |p|
      p[:body] = ActionController::Base.helpers.sanitize(p[:body])
    end
  end
end
