import accessibleAutocomplete from 'accessible-autocomplete'
import debounce from 'lodash.debounce'

const MINIMUM_QUERY_LENGTH = 3
const QUERY_DEBOUNCE_MS = 800

function institutionPicker (options) {
  if (!options.element) { throw new Error('element is not defined') }
  if (!options.id) { throw new Error('id is not defined') }

  accessibleAutocomplete({
    element: options.element,
    ...options
  })
}

async function fetchSource(lookupPath, query) {
  const res  = await fetch(`/${lookupPath}.json?name=${encodeURIComponent(query)}` );

  if (!res.ok) {
    return [];
  }

  const data = await res.json();
  return data;
}

function normaliseQuery(query) {
  return query.trim().replace(/\s+/g, ' ')
}

institutionPicker.enhanceSelectElement = (configurationOptions) => {
  if (!configurationOptions.selectElement) { throw new Error('selectElement is not defined') }

  let previousQuery = ''

  configurationOptions.onConfirm = function(object) {
    if (object !== undefined) {
      configurationOptions.selectElement.value = object.id
    }
  }

  configurationOptions.minLength = MINIMUM_QUERY_LENGTH
  configurationOptions.defaultValue = configurationOptions.selectElement.dataset.defaultValue || ""
  configurationOptions.displayMenu = "overlay"

  configurationOptions.templates = {
    inputValue: function(object) {
      if (object === undefined) {
        return ""
      } else {
        return [object.urn, object.name, object.address].filter(n => n).join(' - ')
      }
    },
    suggestion: function(object) {
      if (object === undefined) {
        return ""
      } else {
        return [object.urn, object.name, object.address].filter(n => n).join(' - ')
      }
    }
  }

  configurationOptions.source = debounce( async ( query, populateResults ) => {
    const normalisedQuery = normaliseQuery(query)

    if (normalisedQuery.length < MINIMUM_QUERY_LENGTH || normalisedQuery === previousQuery) {
      populateResults([])
      return
    }

    previousQuery = normalisedQuery

    try {
      const res = await fetchSource(configurationOptions.lookupPath, normalisedQuery);
      populateResults(res);
    } catch (_) {
      populateResults([]);
    }
  }, QUERY_DEBOUNCE_MS )

  if (configurationOptions.name === undefined) configurationOptions.name = ''

  if (configurationOptions.id === undefined) {
    if (configurationOptions.selectElement.id === undefined) {
      configurationOptions.id = ''
    } else {
      configurationOptions.id = configurationOptions.selectElement.id
    }
  }

  if (configurationOptions.autoselect === undefined) configurationOptions.autoselect = true

  const element = document.createElement('div')

  configurationOptions.selectElement.parentNode.insertBefore(element, configurationOptions.selectElement)

  institutionPicker({
    ...configurationOptions,
    element: element
  })

  configurationOptions.selectElement.style.display = 'none'
  configurationOptions.selectElement.id = configurationOptions.selectElement.id + '-select'
}

export default institutionPicker
