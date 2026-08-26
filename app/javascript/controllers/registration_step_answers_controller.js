import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container", "type"];
  static values = { registrationStepId: Number, url: String };

  connect() {
    this.load();
  }

  async load() {
    const type = this.typeTarget.value;

    if (!type) {
      this.containerTarget.innerHTML = "";
      return;
    }

    const url = new URL(this.urlValue, window.location.origin);
    url.searchParams.set("type", type);

    if (this.hasRegistrationStepIdValue) {
      url.searchParams.set("registration_step_id", this.registrationStepIdValue);
    }

    const response = await fetch(url, {
      headers: {
        "Accept": "text/html",
      },
    });

    if (response.ok) {
      this.containerTarget.innerHTML = await response.text();
    }
  }
}
