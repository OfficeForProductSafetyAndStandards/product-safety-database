require "rails_helper"

RSpec.feature "Manage a case's documents" do

  let(:investiation) { creat(:investigation) }

  before { sign_in create(:user, :activated, :has_viewed_introduction) }
end
