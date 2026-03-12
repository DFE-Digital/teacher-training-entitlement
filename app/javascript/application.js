// Entry point for the build script in your package.json
require.context('govuk-frontend/dist/govuk/assets');

import Rails from 'rails-ujs';
import accessibleAutocomplete from 'accessible-autocomplete';

import institutionPicker from "./institution-picker";
import cookieBanner from "./cookie-banner";
import print from "./print";

Rails.start();
import * as GOVUKFrontend from 'govuk-frontend'


window.GOVUKFrontend = GOVUKFrontend;

window.onload = function init() {
  window.GOVUKFrontend.initAll();
};

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
