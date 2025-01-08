FactoryBot.define do
  factory :email, class: "Correspondence::Email" do
    email_subject { "Re: safety issue" }
    details { "Please call me." }
    correspondence_date { Date.parse("2019-01-02") }
  end
end
