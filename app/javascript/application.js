// Entry point for the build script in your package.json
require.context('govuk-frontend/dist/govuk/assets');

import Rails from 'rails-ujs';
import { Application } from "@hotwired/stimulus";
import accessibleAutocomplete from 'accessible-autocomplete';

import RegistrationStepAnswersController from "./controllers/registration_step_answers_controller";
import institutionPicker from "./institution-picker";
import cookieBanner from "./cookie-banner";
import print from "./print";
import HMRCFrontend from "hmrc-frontend/hmrc/all.js";

Rails.start();
const application = Application.start();
application.register("registration-step-answers", RegistrationStepAnswersController);

import * as GOVUKFrontend from 'govuk-frontend'


window.GOVUKFrontend = GOVUKFrontend;

GOVUKFrontend.initAll();
HMRCFrontend.initAll();

if (document.querySelector('[data-picker="school"]')) {
  institutionPicker.enhanceSelectElement({
    selectElement: document.querySelector('[data-picker="school"]'),
    lookupPath: 'institutions',
  })
}

if (document.querySelector('[data-picker="nursery"]')) {
  institutionPicker.enhanceSelectElement({
    selectElement: document.querySelector('[data-picker="nursery"]'),
    lookupPath: 'institutions',
  })
}

if (document.querySelector('[data-picker="private-childcare-provider"]')) {
  institutionPicker.enhanceSelectElement({
    selectElement: document.querySelector('[data-picker="private-childcare-provider"]'),
    lookupPath: 'private_childcare_providers'
  })
}
