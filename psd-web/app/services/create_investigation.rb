class CreateInvestigation
  include Interactor

  delegate :investigation, :current_user, to: :context

  def call
    Investigation.transaction do
      build_case_creators
      build_case_owners

      context.investigation = investigation
      # byebug
      return if investigation.save!

      context.fail!
    end
  end

private

  def build_case_creators
    investigation.build_case_creator_team(collaborators_attributes(current_user.team))
    investigation.build_case_creator_user(collaborators_attributes(current_user))
  end

  def build_case_owners
    investigation.build_case_owner_team(collaborators_attributes(current_user.team))
    investigation.build_case_owner_user(collaborators_attributes(current_user))
  end

  def collaborators_attributes(collaborating)
    { added_by_user: current_user, include_message: false, collaborating: collaborating }
  end
end
