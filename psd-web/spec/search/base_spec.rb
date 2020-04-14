require "rails_helper"

RSpec.describe Search::Base, :with_elasticsearch do

  let(:current_user_id) { @user11.id }
  let(:current_team_id) { @team1.id }

  let(:q) { "" }
  let(:unchecked) { "unchecked" }
  let(:checked) { "checked" }

  let(:assigned_to_me) { unchecked }
  let(:assigned_to_someone_else) { unchecked }
  let(:assigned_to_someone_else_id) { unchecked }
  let(:assigned_to_team_0) { unchecked }

  let(:created_by_me) { unchecked }
  let(:created_by_someone_else) { unchecked }
  let(:created_by_someone_else_id) { unchecked }
  let(:created_by_team_0) { unchecked }

  let(:allegation) { unchecked }
  let(:enquiry) { unchecked }
  let(:project) { unchecked }

  let(:status_open) { checked }
  let(:status_closed) { checked }

  let(:sort_by) { unchecked }

  let(:params) do
    {
      "q" => q,
      "assigned_to_me" => assigned_to_me,
      "assigned_to_someone_else" => assigned_to_someone_else,
      "assigned_to_someone_else_id" => assigned_to_someone_else_id,
      "assigned_to_team_0" => assigned_to_team_0,

      "created_by_me" => created_by_me,
      "created_by_someone_else" => created_by_someone_else,
      "created_by_someone_else_id" => created_by_someone_else_id,
      "created_by_team_0" => created_by_team_0,

      "allegation" => allegation,
      "enquiry" => enquiry,
      "project" => project,

      "status_closed" => status_closed,
      "status_open" => status_open,

      "sort_by" => sort_by
    }
  end

  before(:all) do
    WebMock.disable!
    Activity.instance_eval { @disable_update_email = true }

    @team1 = create(:team)
    @user11 = create(:user, teams: [@team1])
    @user12 = create(:user, teams: [@team1])

    @team2 = create(:team)
    @user21 = create(:user, teams: [@team2])
    @user22 = create(:user, teams: [@team2])

    @allegation1 = create(:allegation, assignable: @team1, description: "glider", product_category: "airplane")
    @allegation2 = create(:allegation, is_closed: true, assignable: @user11)
    @enquiry1 = create(:enquiry, assignable: @team1)
    @enquiry2 = create(:enquiry, is_closed: true, assignable: @user12)
    @project1 = create(:project, assignable: @team2)
    @project2 = create(:project, is_closed: true, assignable: @user22)

    @source1 = create(:user_source, user: @user11, sourceable: @allegation1)
    @source2 = create(:user_source, user: @user11, sourceable: @allegation2)
    @source3 = create(:user_source, user: @user12, sourceable: @enquiry1)
    @source4 = create(:user_source, user: @user21, sourceable: @enquiry2)
    @source5 = create(:user_source, user: @user21, sourceable: @project1)
    @source6 = create(:user_source, user: @user22, sourceable: @project2)

    investigations = []
    investigations << @allegation1
    investigations << @allegation2
    investigations << @enquiry1
    investigations << @enquiry2
    investigations << @project1
    investigations << @project2

    investigations.map(&:reload)
    # Its crucial to update index after all investigations were created
    Search::Index.update_index
  end

  let(:team1) { @team1 }
  let(:user11) { @user11 }
  let(:user12) { @user12 }

  let(:team2) { @team2 }
  let(:user21) { @user21 }
  let(:user22) { @user22 }

  let(:allegation1) { @allegation1 }
  let(:allegation2) { @allegation2 }
  let(:enquiry1)    { @enquiry1 }
  let(:enquiry2)    { @enquiry2 }
  let(:project1)    { @project1 }
  let(:project2)    { @project2 }

  let(:source1) { @source1 }
  let(:source2) { @source2 }
  let(:source3) { @source3 }
  let(:source4) { @source4 }
  let(:source5) { @source5 }
  let(:source6) { @source6 }

  after do
    WebMock.enable!
    Activity.instance_eval { @disable_update_email = false }
    DatabaseCleaner.clean
  end

  let(:search_form)   { Search::Form.new(params) }
  let(:search_engine) { described_class.new(search_form: search_form, user_id: current_user_id, team_id: current_team_id) }

  shared_examples_for "search" do
    it "return correct products" do
      expect(search_engine.search.map(&:id)).to eq(expected_products.map(&:id))
    end
  end

  it_behaves_like "search" do
    let(:status_closed) { unchecked }
    let(:expected_products) do
      [project1, enquiry1, allegation1,]
    end
  end

  context "simple text search" do
    context "by description" do
      it_behaves_like "search" do
        let(:q) { "glider" }
        let(:expected_products) do
          [allegation1]
        end
      end
    end

    context "by category" do
      it_behaves_like "search" do
        let(:q) { "airplane" }
        let(:expected_products) do
          [allegation1]
        end
      end
    end
  end

  context "include all cases" do
    it_behaves_like "search" do
      let(:expected_products) do
        [project2, project1, enquiry2, enquiry1, allegation2, allegation1,]
      end
    end
  end

  describe "Created by filter" do
    # let(:source3) { create(:user_source, user: user12, sourceable: enquiry1) }

    context "by me" do
      it_behaves_like "search" do
        let(:created_by_me) { checked }
        let(:current_user_id) { user11.id }
        let(:expected_products) do
          [allegation2, allegation1,]
        end
      end
    end

    context "by my team" do
      it_behaves_like "search" do
        let(:created_by_team_0) { checked }
        let(:current_team_id) { team1.id }
        let(:expected_products) do
          [enquiry1, allegation2, allegation1,]
        end
      end
    end

    context "by other" do
      let(:created_by_someone_else) { checked }

      context "no user or team selected" do
        it_behaves_like "search" do
          let(:expected_products) do
            [project2, project1, enquiry2]
          end
        end
      end

      context "team" do
        it_behaves_like "search" do
          let(:created_by_someone_else_id) { team1.id }
          let(:expected_products) do
            [enquiry1, allegation2, allegation1,]
          end
        end
      end

      context "by user" do
        it_behaves_like "search" do
          let(:created_by_someone_else_id) { user11.id }
          let(:expected_products) do
            [allegation2, allegation1,]
          end
        end
      end
    end

    context "all checked" do
      it_behaves_like "search" do
        let(:created_by_me) { checked }
        let(:current_user_id) { user11.id }
        let(:created_by_team_0) { checked }
        let(:current_team_id) { team1.id }
        let(:created_by_someone_else) { checked }
        let(:created_by_someone_else_id) { team2.id }

        let(:expected_products) do
          [project2, project1, enquiry2, enquiry1, allegation2, allegation1,]
        end
      end
    end
  end

  context "By type" do
    context "project and allegation" do
      it_behaves_like "search" do
        let(:project) { checked }
        let(:allegation) { checked }
        let(:expected_products) do
          [project2, project1, allegation2, allegation1]
        end
      end
    end

    context "project" do
      it_behaves_like "search" do
        let(:project) { checked }
        let(:expected_products) do
          [project2, project1,]
        end
      end
    end

    context "allegation" do
      it_behaves_like "search" do
        let(:allegation) { checked }
        let(:expected_products) do
          [allegation2, allegation1,]
        end
      end
    end

    context "enquiry" do
      it_behaves_like "search" do
        let(:enquiry) { checked }
        let(:expected_products) do
          [enquiry2, enquiry1,]
        end
      end
    end
  end

  context "Assignee" do
    context "to me" do
      it_behaves_like "search" do
        let(:assigned_to_me) { checked }
        let(:current_user_id) { user11.id }

        let(:expected_products) do
          [allegation2]
        end
      end
    end

    context "to my team" do
      it_behaves_like "search" do
        let(:assigned_to_team_0) { checked }
        let(:current_team_id) { team1.id }

        let(:expected_products) do
          [enquiry2, enquiry1, allegation2, allegation1]
        end
      end
    end

    context "other" do
      let(:assigned_to_someone_else) { checked }

      context "no user or team selected" do
        it_behaves_like "search" do
          let(:expected_products) do
            [project2, project1]
          end
        end
      end

      context "to user" do
        it_behaves_like "search" do
          let(:assigned_to_someone_else_id) { user11.id }

          let(:expected_products) do
            [allegation2]
          end
        end
      end

      context "to team" do
        it_behaves_like "search" do
          let(:assigned_to_someone_else_id) { team1.id }

          let(:expected_products) do
            [enquiry2, enquiry1, allegation2, allegation1]
          end
        end
      end
    end
  end
end
