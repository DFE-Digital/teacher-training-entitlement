# How the API works

The Application Programming Interface (API) lets your software system securely connect with ours to:

* collect new applications
* accept or reject applications
* get details of all applications and participants
* submit declarations via applications
* defer, resume or withdraw via applications
* view outcomes and financial statements
* retrieve active cohorts for the resume flow


## Key parts of the API

<strong>Client:</strong> This is your system that sends or receives data.

<strong>API request:</strong> Your system sends a structured request to the API. For example, you might request a list of participants or submit a declaration against an application.

<strong>Server:</strong> The API receives the request, processes it, and connects with the Department for Education's database.

<strong>API response:</strong> The API sends back the requested data in a format your system can understand, such as JSON. For example, you might receive confirmation that a declaration has been submitted or see why an application was rejected.

## API resources

* **Applications** - Central resource: accept, reject, declare, defer, withdraw, resume, change delivery partner
* **Cohorts** - List active cohorts (used when resuming a deferred application)
* **Participants** - Read-only view of participants and their enrolments
* **Declarations** - Query declarations and void them
* **Statements** - View financial statements and payment information
* **Delivery Partners** - Retrieve delivery partner information
* **Outcomes** - Query assessment outcomes

## Why this matters

The API helps:

* reduce manual data entry
* improve accuracy and speed
* give providers real-time access to application and participant data

## Security and access

The API includes rules to:

* control who can access the data
* protect sensitive information
* ensure secure communication between systems
