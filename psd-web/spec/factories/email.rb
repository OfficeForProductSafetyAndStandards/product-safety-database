FactoryBot.define do
  factory :email, class: "Correspondence::Email" do
    correspondence_date { Date.parse("2019-01-02") }

    correspondence_date_day { correspondence_date.day }
    correspondence_date_month { correspondence_date.month }
    correspondence_date_year { correspondence_date.year }
  end
end
