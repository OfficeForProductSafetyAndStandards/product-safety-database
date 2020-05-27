class Collaboration < ApplicationRecord
  belongs_to :investigation
  belongs_to :collaborator, polymorphic: true

  belongs_to :added_by_user, class_name: :User

  validates :message, presence: true, if: :include_message

  validates :include_message, inclusion: { in: [true, false] }

  attr_reader :include_message

  def include_message=(value)
    @include_message = if value.is_a? String
                         (value == "true")
                       else
                         value
                       end
  end
end
