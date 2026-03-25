# How courses work

## The application stage

1. Once someone has registered with us to do a course, providers can view their application data via our API.
2. Providers complete their own suitability and application processes.
3. Providers process applications via our API. This is where providers can confirm whether or not training will be DfE-funded.
4. Providers set successful applicants up on their training portals.

## Training starts

1. Providers train participants as per details set out in the contract.
2. Providers submit started declarations via the API against the application to notify DfE that participants have started their courses.
3. DfE pays providers output payments for started declarations.

## Training continues

1. Providers continue to train participants as per details set out in the contract.

## After the participant has completed their course

1. Providers complete training participants as per details set out in the contract.
2. Providers will submit completed declarations via the API against the application, including participant outcomes, to notify DfE participants have completed the course.
3. DfE will pay providers output payments for completed declarations.

## Changes during training

During training, providers may need to update DfE about changes to a participant's status. All changes are made via application endpoints:

* **Defer** — if a participant needs to temporarily pause their course, the provider defers the application. Deferred applications have a deadline by which they must be resumed, otherwise they are automatically withdrawn.
* **Resume** — when a deferred participant is ready to resume, the provider selects a target cohort from the `/cohorts` endpoint and resumes the application.
* **Withdraw** — if a participant decides to leave the course, the provider withdraws the application.
* **Change delivery partner** — if the delivery partner changes, the provider updates this on the application.

## Other considerations

It's worth noting that:

* providers can view financial statements via the API
* participants are read-only in the API — all lifecycle actions are performed on applications
* DfE will only make payments for participants if providers have accepted course applications. Accepting applications is a separate request to submitting a 'started' declaration (which notifies DfE a participant has started training)
