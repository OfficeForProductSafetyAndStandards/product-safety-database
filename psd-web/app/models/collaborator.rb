class Collaborator < ApplicationRecord
  belongs_to :investigation
  belongs_to :team

  belongs_to :added_by_user, class_name: :User
end
