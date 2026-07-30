# https://www.gov.uk/guidance/style-guide/a-to-z-of-gov-uk-style#dates
Date::DATE_FORMATS[:govuk]        = "%-d %B %Y" # 2 January 1998
Date::DATE_FORMATS[:govuk_short]  = "%-d %b %Y" # 2 Jan 1998
Date::DATE_FORMATS[:govuk_approx] = "%B %Y"     # January 1998
Date::DATE_FORMATS[:succint] = "%Y-%m-%d"       # 1998-01-01

Time::DATE_FORMATS[:govuk_short] = "%-d %b %Y %-l:%M%P"
Time::DATE_FORMATS[:govuk_date_only] = "%e %B %Y"
