RSpec.feature "Searching notifications", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:team) { create(:team) }
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, team:) }

  before do
    sign_in user
    click_on "Notifications"
  end

  context "when there are no notifications" do
    context "when the user is on the your notifications page" do
      before do
        click_on "Your notifications"
      end

      it "explains that the user has no notifications" do
        expect(page).to have_content "You have no open notifications."
        expect(highlighted_tab).to eq "Your notifications"
        expect(page).to have_selector(".govuk-breadcrumbs__link", text: "Notifications")
      end
    end

    context "when the user is on the team notifications page" do
      before do
        click_on "Team notifications"
      end

      it "explains that the team has no notifications" do
        expect(page).to have_content "The team has no open notifications."
        expect(highlighted_tab).to eq "Team notifications"
        expect(page).to have_selector(".govuk-breadcrumbs__link", text: "Notifications")
      end
    end

    context "when the user is on the assigned notifications page" do
      before do
        click_on "Assigned notifications"
      end

      it "explains that the team has no assigned notifications" do
        expect(page).to have_content "There are no open notifications your team has been added to."
        expect(highlighted_tab).to eq "Assigned notifications"
        expect(page).to have_selector(".govuk-breadcrumbs__link", text: "Notifications")
      end
    end
  end

  context "when there are notifications" do
    let(:other_user_same_team) { create(:user, :activated, has_viewed_introduction: true, team:) }
    let!(:user_notification) { create(:notification, :with_products, creator: user, user_title: "User notification title") }
    let!(:user_notification_without_products) { create(:notification, creator: user, user_title: "User notification no products title") }
    let!(:other_notification) { create(:notification, user_title: "Other notification title") }
    let!(:team_notification) { create(:notification, creator: other_user_same_team, user_title: "Team notification title") }

    let(:different_team) { create :team, name: "Different team" }
    let(:different_user) { create :user, :activated, has_viewed_introduction: true, team: different_team }
    let!(:different_team_notification) { create(:notification, creator: different_user, user_title: "Different team notification title") }

    before do
      Investigation.reindex
    end

    context "when the user is on the your notifications page" do
      before do
        click_on "Your notifications"
      end

      it "shows notifications that are owned by the user" do
        expect(page).to have_selector("td.govuk-table__cell", text: user_notification.pretty_id)
        expect(page).to have_selector("td.govuk-table__cell", text: user_notification_without_products.pretty_id)
        expect(page).not_to have_selector("td.govuk-table__cell", text: other_notification.pretty_id)
        expect(page).not_to have_selector("td.govuk-table__cell", text: team_notification.pretty_id)
        expect(page).not_to have_selector("td.govuk-table__cell", text: different_team_notification.pretty_id)
      end

      it "indicates which notifications do not have a product attached" do
        within(sprintf('td[headers="item_investigation_%{id} status_investigation_%{id}"]', id: user_notification.id)) do
          expect(page).not_to have_content("This notification has no product")
        end

        within(sprintf('td[headers="item_investigation_%{id} status_investigation_%{id}"]', id: user_notification_without_products.id)) do
          expect(page).to have_content("This notification has no product")
        end
      end

      context "when we click on a notification" do
        before do
          within "#item_investigation_#{user_notification.id}" do
            click_on user_notification.title
          end
        end

        it "takes us to the notification page" do
          expect(page).to have_current_path("/cases/#{user_notification.pretty_id}")
        end

        it "has 'Your notifications' in the breadcrumb" do
          expect(page).to have_selector(".govuk-breadcrumbs__link", text: "Home")
          expect(page).to have_selector(".govuk-breadcrumbs__link", text: "Notifications")
          expect(page).to have_selector(".govuk-breadcrumbs__link", text: "Your notifications")
        end
      end

      context "when less than 12 notifications" do
        it "does not show the sort filter drop down" do
          expect(page).not_to have_css("form dl.opss-dl-select dd")
        end
      end

      context "when more than 11 notifications" do
        before do
          create_list(:notification, 11, creator: user)
          Investigation.reindex
          visit "/cases/your-cases"
        end

        it "does show the sort filter drop down with 'newest cases' sorting option selected" do
          expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newest notifications")
        end

        it "does not change table headers when user changes the filter options" do
          expect(page).to have_css("th#updated")
          expect(page).not_to have_css("th#created")

          within "form dl.govuk-list.opss-dl-select" do
            click_on "Oldest notifications"
          end

          expect(page).to have_css("th#updated")
          expect(page).not_to have_css("#thcreated")
        end
      end
    end

    context "when the user is on the team notifications page" do
      before do
        click_on "All notifications"
        click_on "Team notifications"
      end

      it "shows cases that are owned by the users team" do
        expect(page).to have_selector("td.govuk-table__cell", text: user_notification.pretty_id)
        expect(page).to have_selector("td.govuk-table__cell", text: team_notification.pretty_id)
        expect(page).not_to have_selector("td.govuk-table__cell", text: other_notification.pretty_id)
        expect(page).not_to have_selector("td.govuk-table__cell", text: different_team_notification.pretty_id)
      end

      it "indicates which cases do not have a product attached" do
        within(sprintf('td[headers="item_investigation_%{id} status_investigation_%{id}"]', id: user_notification.id)) do
          expect(page).not_to have_content("This notification has no product")
        end

        within(sprintf('td[headers="item_investigation_%{id} status_investigation_%{id}"]', id: user_notification_without_products.id)) do
          expect(page).to have_content("This notification has no product")
        end
      end

      context "when we click on a notification" do
        before do
          within "#item_investigation_#{team_notification.id}" do
            click_on team_notification.title
          end
        end

        it "takes us to the notifications page" do
          expect(page).to have_current_path("/cases/#{team_notification.pretty_id}")
        end

        it "has 'Team notifications' in the breadcrumb" do
          expect(page).to have_selector(".govuk-breadcrumbs__link", text: "Home")
          expect(page).to have_selector(".govuk-breadcrumbs__link", text: "Notifications")
          expect(page).to have_selector(".govuk-breadcrumbs__link", text: "Team notifications")
        end
      end

      context "when less than 12 notifications" do
        it "does not show the sort filter drop down" do
          expect(page).not_to have_css("form dl.opss-dl-select dd")
        end
      end

      context "when more than 11 notifications" do
        before do
          create_list(:notification, 11, creator: other_user_same_team)
          Investigation.reindex
          visit "/cases/team-cases"
        end

        it "does show the sort filter drop down with 'newest cases' sorting option selected" do
          expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newest notifications")
        end

        it "does not change table headers when user changes the filter options" do
          expect(page).to have_css("th#updated")
          expect(page).not_to have_css("th#created")

          within "form dl.govuk-list.opss-dl-select" do
            click_on "Oldest notifications"
          end

          expect(page).to have_css("th#updated")
          expect(page).not_to have_css("th#created")
        end
      end
    end

    context "when the user is on the all notifications page" do
      before do
        click_on "All notifications"
      end

      it "shows all notifications" do
        expect(page).to have_selector("td.govuk-table__cell", text: user_notification.pretty_id)
        expect(page).to have_selector("td.govuk-table__cell", text: other_notification.pretty_id)
        expect(page).to have_selector("td.govuk-table__cell", text: team_notification.pretty_id)
        expect(page).to have_selector("td.govuk-table__cell", text: different_team_notification.pretty_id)
      end

      it "highlights the all notifications tab" do
        expect(highlighted_tab).to eq "All notifications – Search"
      end

      context "when we click on a notifications" do
        before do
          within "#item_investigation_#{user_notification.id}" do
            click_on user_notification.title
          end
        end

        it "takes us to the notifications page" do
          expect(page).to have_current_path("/cases/#{user_notification.pretty_id}")
        end

        it "has 'All notifications' in the breadcrumb" do
          expect(page).to have_selector(".govuk-breadcrumbs__link", text: "Home")
          expect(page).to have_selector(".govuk-breadcrumbs__link", text: "Notifications")
          expect(page).to have_selector(".govuk-breadcrumbs__link", text: "All notifications")
        end
      end

      context "when less than 12 notifications" do
        it "does not show the sort filter drop down" do
          expect(page).not_to have_css("form dl.opss-dl-select dd")
        end
      end

      context "when more than 11 notifications" do
        before do
          create_list(:notification, 11)
          Investigation.reindex
          visit "/cases/all-cases"
        end

        it "does show the sort filter drop down with 'recent cases' sorting option selected" do
          expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Recent updates")
        end

        it "changes table headers when user changes the filter options" do
          expect(page).to have_css("th#updated")
          expect(page).not_to have_css("th#created")

          within "form dl.govuk-list.opss-dl-select" do
            click_on "Oldest notifications"
          end

          expect(page).to have_css("th#created")
          expect(page).not_to have_css("th#updated")
        end
      end
    end

    context "when the different team notification is assigned to the user's team" do
      before do
        AddTeamToNotification.call(user:, notification: different_team_notification, team:, collaboration_class: Collaboration::Access::Edit)
        Investigation.reindex
        click_on "All notifications"
      end

      context "when on team notifications page" do
        before do
          visit "/cases/team-cases"
        end

        it "does not show the notification" do
          expect(page).not_to have_selector("td.govuk-table__cell", text: different_team_notification.pretty_id)
        end
      end

      context "when on assigned notifications page" do
        before do
          visit "/cases/assigned-cases"
        end

        it "shows the notification" do
          expect(page).to have_selector("td.govuk-table__cell", text: different_team_notification.pretty_id)
        end
      end

      context "when on all notifications page" do
        before do
          visit "/cases/all-cases"
        end

        it "shows the notification" do
          expect(page).to have_selector("td.govuk-table__cell", text: different_team_notification.pretty_id)
        end
      end
    end
  end

  def highlighted_tab
    find(".opss-left-nav__active").text
  end
end
