require "rails_helper"

RSpec.describe DeleteTeam, :with_stubbed_mailer, :with_stubbed_elasticsearch do

  it "marks the team as deleted" do
  end

  context "when the team has users" do
    it "migrates the users to the new team" do
    end

    it "retains the users' roles in the new team" do
    end

    it "sends a confirmation email to each affected user" do
    end

    context "when a user is attributed to historic activity on a case" do
      it "retains the user attribution" do
      end
    end
  end

  context "when the team has created a case" do
    it "retains the team as the case creator" do
    end
  end

  context "when a user on the team has created a case" do
    it "retains the user as the case creator" do
    end
  end

  context "when the team is the owner of a case" do
    it "transfers ownership of the case to the new team" do
    end

    it "adds activity showing the case ownership changed to the new team" do
    end

    it "adds activity showing the old team removed from the case" do
    end

    it "does not send notification e-mails" do
    end

    it "removes the previous collaborator access from the new team" do
    end
  end

  context "when a user in the team is the owner of a case" do
    it "retains the ownership of the case with the same user in the new team" do
    end

    it "updates the owner team to the user's new team" do
    end
  end

  context "when the team is a collaborator on a case owned by another team" do
    it "adds activity showing the old team removed from the case" do
    end

    it "does not send notification e-mails" do
    end

    context "when the new team is not already a collaborator on the case" do
      it "adds activity showing the new team added to the case" do
      end

      it "retains the old team's access level to the case" do
      end
    end

    context "when the new team is already a collaborator on the case" do
      it "does not add activity showing the new team added to the case" do
      end

      context "when the new team has the same level of access to the case as the old team" do
        it "does not change the new team's access level on the case" do
        end
      end

      context "when the new team has read-only access to the case but the old team had edit access" do
        it "does not change the new team's access level on the case" do
        end
      end

      context "when the new team has edit access to the case but the old team had read-only access" do
        it "does not change the new team's access level on the case" do
        end
      end

      context "when the new team is the owner of the case" do
        it "does not change the new team's access level on the case" do
        end
      end
    end
  end
end
