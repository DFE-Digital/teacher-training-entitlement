# Get started

## Connect to the API

Providers integrate their local CRM systems by connecting to this API's test environments.

## Request an authentication (bearer) token

Providers need to use a unique authentication (bearer) token to connect to the API.

[Email us](mailto:continuing-professional-development@digital.education.gov.uk) if you do not already have this token. We'll send it via secure email.

The tokens do not expire.

<div class="govuk-warning-text">
  <span class="govuk-warning-text__icon" aria-hidden="true">!</span>
  <strong class="govuk-warning-text__text">
    <span class="govuk-visually-hidden">Warning</span>
    Do not share tokens in publicly accessible documents or repositories.
  </strong>
</div>

### How to use an authentication token

Include an authentication token in all requests to the API by adding an `Authorization` request header (not as part of the URL) in the following format:

```
Authorization: Bearer {token}
```

Unauthenticated requests will receive an `UnauthorizedResponse` with a `401` error code.

## Test environments

The test environments feature all the API request endpoints and have been populated with seed data which cover scenarios where users have:

* one application
* multiple applications
* accepted applications
* rejected applications

The base URL for the API's test environments is:

* [https://sandbox.teacher-training-entitlement.education.gov.uk](https://sandbox.teacher-training-entitlement.education.gov.uk)

The sandbox environment will be populated with seed data that are needed to test specific scenarios 

## Access YAML format API specs

Provider development teams can also access the OpenAPI spec in YAML format:

* [view the OpenAPI version 3 spec](/api/docs/v1/swagger.yaml)

Providers can use API testing tools such as Postman to make test API calls. Providers can import the API as a collection by using [Postman’s](https://www.postman.com/) import feature and copying in the YAML URL of the API spec.

### Rate limits

**Service rate limit**: The service allows 1,000 requests every 5 minutes in total.

**Per-IP limit**: Each IP address can make 300 requests in 5 minutes.

These limits help prevent the service from getting overloaded.

### Best practices for efficient requests

**Slow down requests**: Providers should add a small delay (e.g. 100ms) between requests to avoid overwhelming the system.

**Request more data at once**: Use a larger page size (e.g. 300) to reduce the number of requests. This allows fetching up to 90,000 declarations in 5 minutes, which should be enough.

If the limit is exceeded, providers will see `429` HTTP status codes.

This limit on requests for each authentication key is calculated on a rolling basis.

## Syncing data best practice

### Polling the API regularly

To make sure no applications, declarations or participants are missed:

* poll the relevant `GET endpoints` multiple times a day, ensuring you include an `updated_since` filter
* use the default pagination of 100 records per page
* keep polling and incrementing the page number until you receive an empty response

Contact the DfE using our Teams channel if you need further details.

### Performing a full sync

We recommend you do a full sync of all records in the API once a week without using the <code>updated_since</code> filters.

The DfE can coordinate ‘windows’ (set time periods) for providers to do this at times when there is a low background load on the service. Contact the DfE using our Teams channel for more details.

### Polling windows

Always poll 2 windows back from your last successful poll. This guarantees that all participant data is captured. For example:

* at 3:15pm enter the following request - <code>/api/v1/applications?filter[updated_since]=2025-01-28T13:15:00Z</code>
* at 4:15pm enter the following request - <code>/api/v1/applications?filter[updated_since]=2025-01-28T14:15:00Z</code>

Try polling randomly rather than on the hour to prevent system overload.
