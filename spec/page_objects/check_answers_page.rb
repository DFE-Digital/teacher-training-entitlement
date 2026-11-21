class CheckAnswersPage < SitePrism::Page
  set_url "/registration/check-answers"
  set_url_matcher %r{/registration/(?:[\w-]+/)?check-answers\z}

  section :summary_list, SummaryListSection, ".govuk-summary-list"
end
