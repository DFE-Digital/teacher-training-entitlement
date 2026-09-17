function eventParamsFor(element) {
  return {
    button_text: element.dataset.googleAnalyticsEventButtonText || element.textContent.trim(),
    page_path: element.dataset.googleAnalyticsEventPagePath || window.location.pathname,
  }
}

export default function googleAnalyticsEvents() {
  document.addEventListener("click", (event) => {
    const element = event.target.closest("[data-google-analytics-event]")

    if (!element || typeof window.gtag !== "function") {
      return
    }

    window.gtag("event", element.dataset.googleAnalyticsEvent, eventParamsFor(element))
  })
}
