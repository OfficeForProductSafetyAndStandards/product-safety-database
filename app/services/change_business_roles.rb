class ChangeBusinessRoles
  include Interactor

  delegate :roles, :online_marketplace_id, :new_online_marketplace_name, :authorised_representative_choice, :notification, :business, :user, to: :context

  def call
    context.fail!(error: "No roles supplied") unless roles.is_a?(Array)

    ActiveRecord::Base.transaction do
      InvestigationBusiness.where(business:, investigation: notification, relationship: roles_to_be_deleted).destroy_all

      roles_to_be_added.each do |role|
        if role == "online_marketplace"
          if online_marketplace_id
            InvestigationBusiness.create!(business:, investigation: notification, relationship: role, online_marketplace_id:)
          elsif new_online_marketplace_name
            new_online_marketplace = OnlineMarketplace.create!(name: new_online_marketplace_name, approved_by_opss: false)
            InvestigationBusiness.create!(business:, investigation: notification, relationship: role, online_marketplace: new_online_marketplace)
          end
        elsif role == "authorised_representative"
          InvestigationBusiness.create!(business:, investigation: notification, relationship: authorised_representative_choice)
        else
          InvestigationBusiness.create!(business:, investigation: notification, relationship: role)
        end
      end
    end
  end

private

  def roles_to_be_deleted
    existing_roles - roles.compact_blank!
  end

  def roles_to_be_added
    roles.compact_blank! - existing_roles
  end

  def existing_roles
    InvestigationBusiness.where(business:, investigation: notification).pluck(:relationship)
  end
end
