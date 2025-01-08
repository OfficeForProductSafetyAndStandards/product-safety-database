class MoveOwnersToCollaboration < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      Investigation.all.find_each do |i|
        owner = i[:owner_type].constantize.find(i[:owner_id])
        i.owner = owner
        i.save!
      end
    end
  end
end
