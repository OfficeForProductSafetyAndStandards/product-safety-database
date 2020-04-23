module PsdServiceInterface
  extend ActiveSupport::Concern

  class_methods do
    def new(args)
      this = super()
      args.keys.each do |key|
        self.attr_accessor key.to_sym
        this.send("#{key}=".to_sym, args[key])
      end
      this.instance_variable_set(:@success, true)
      this
    end

    def call(args)
      obj = new(args)
      obj.call
      obj
    end
  end

  def success?
    @success
  end

  def fail!
    @success = false
  end
end

class AddTeamToAnInvestigation
  include PsdServiceInterface

  attr_accessor :collaborator

  # rubocop:disable Lint/SuppressedException
  def call
    self.collaborator = investigation.collaborators.new(
      team_id: team_id,
      include_message: include_message,
      added_by_user: current_user,
      message: message
      )

    begin
      if collaborator.save
        NotifyTeamAddedToCaseJob.perform_later(collaborator)

        AuditActivity::Investigation::TeamAdded.create!(
          source: UserSource.new(user: current_user),
          investigation: investigation,
          title: "#{collaborator.team.name} added to #{investigation.case_type.downcase}",
          body: collaborator.message.to_s
        )
      else
        self.fail!
      end
    rescue ActiveRecord::RecordNotUnique
      # Collaborator already added, so return successful but without notfiying the team
      # or creating an audit log.
    end
  end
  # rubocop:enable Lint/SuppressedException
end
