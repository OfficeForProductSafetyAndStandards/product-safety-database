class AddTeamToCaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :team_id
  attribute :message
  attribute :include_message, :boolean, default: nil

  validates_presence_of :team_id
  validates :message, presence: true, if: :include_message
  validates :include_message, inclusion: { in: [true, false] }

  def team
    @team ||= Team.find(team_id)
  end
end
