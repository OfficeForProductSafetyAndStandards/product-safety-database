class CollaborationSerializer < ActiveModel::Serializer
  attributes :collaborator_id, :collaborator_type, :type
end
