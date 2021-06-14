class CommentForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Dirty

  attribute :body

  validates :body, presence: true
  validates :body, length: { maximum: 10_000 }
end
