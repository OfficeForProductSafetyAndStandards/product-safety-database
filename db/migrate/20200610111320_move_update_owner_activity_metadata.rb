class MoveUpdateOwnerActivityMetadata < ActiveRecord::Migration[5.2]
  def change
    klass = AuditActivity::Investigation::UpdateOwner

    klass.all.find_each do |activity|
      next if activity.metadata

      # case owner ID is stored in the title column...
      next unless (owner_id = activity[:title])

      owner = User.find_by(id: owner_id) || Team.find_by(id: owner_id)

      metadata = klass.build_metadata(owner, activity[:body])

      activity.update!(metadata:, title: nil, body: nil)
    end

    klass = AuditActivity::Investigation::AutomaticallyUpdateOwner

    klass.all.find_each do |activity|
      next if activity.metadata

      # case owner ID is stored in the title column...
      next unless (owner_id = activity[:title])

      owner = User.find_by(id: owner_id) || Team.find_by(id: owner_id)

      metadata = klass.build_metadata(owner)

      activity.update!(metadata:, title: nil, body: nil)
    end
  end
end
