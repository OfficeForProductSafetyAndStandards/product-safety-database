Time::DATE_FORMATS[:govuk] = "%e %B %Y"
Date::DATE_FORMATS[:govuk] = ->(date) { date.strftime("%e %B %Y").lstrip }
