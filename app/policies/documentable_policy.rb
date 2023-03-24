class DocumentablePolicy < ApplicationPolicy
  # NOTE: record will be the parent record, not the document!

  def show?
    case record
    when Investigation
      # Users who can view protected details can see case attachments
      Pundit.policy!(user, record).view_protected_details?
    else
      # Anyone can show other types of Documentable
      true
    end
  end

  def create?
    case record
    when Investigation
      # Users who can update the case can attach to it
      Pundit.policy!(user, record).update?
    when Product
      # Users who can update the product can attach to it
      Pundit.policy!(user, record).update?
    else
      # Anyone can attach to a Business or other Documentable
      true
    end
  end

  def update?
    create?
  end

  def destroy?
    update?
  end

  def remove?
    destroy?
  end
end
