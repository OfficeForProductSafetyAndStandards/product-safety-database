FactoryBot.define do
  factory :allegation, class: Investigation::Allegation do
    description { "test allegation" }
    user_title { "test allegation title" }
    is_closed { false }
  end

  factory :enquiry, class: Investigation::Enquiry do
    description { "test enquiry" }
    user_title { "test enquiry title" }
    is_closed { false }
  end

  factory :project, class: Investigation::Project do
    description { "test project" }
    user_title { "test project title" }
    is_closed { false }
  end
end
