class CorrectiveActionTakenForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :corrective_action_taken_yes_no, :boolean
  attribute :corrective_action_taken_no_specific, :string
  attribute :corrective_action_not_taken_reason, :string

  validates :corrective_action_taken_yes_no, inclusion: { in: [true, false] }
  validates :corrective_action_taken_no_specific, inclusion: { in: (Investigation.corrective_action_takens.values - %w[yes]) }, unless: -> { corrective_action_taken_yes_no.nil? || corrective_action_taken_yes_no }
  validates :corrective_action_not_taken_reason, presence: true, if: -> { corrective_action_taken_no_specific == "other" }
  validates :corrective_action_not_taken_reason, length: { maximum: 100 }

  def corrective_action_taken
    if corrective_action_taken_yes_no
      "yes"
    else
      corrective_action_taken_no_specific
    end
  end
end
