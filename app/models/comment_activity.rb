class CommentActivity < Activity
  include SanitizationHelper
  before_validation { trim_line_endings(:body) }
  validates :body, presence: true
  validates :body, length: { maximum: 10_000 }

  def search_index
    body
  end
end
