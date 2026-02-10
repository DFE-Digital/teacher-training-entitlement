# Participant journey

These diagrams provide an overview of the key processes that take place during each phase of an participant’s journey.

## Registering and applying for a course

<div class="card">
  <img src="/images/participant.png" alt="Participant Icon" class="participant">
  <div class="card-text">
    <h2 class="govuk-heading-m">Participant</h2>

    <p class="govuk-body">
      1. Reads the guidance on gov.uk to find out:
    </p>

    <ul class="govuk-list govuk-list--bullet">
      <li>which courses are available</li>
      <li>which providers offer them</li>
      <li>who is eligible for scholarship funding</li>
    </ul>

    <p class="govuk-body">
      2. Registers for a course by providing their information including:
    </p>
    <ul class="govuk-list govuk-list--bullet">
      <li>workplace details</li>
      <li>course and provider choice</li>
    </ul>
  </div>
</div>

<div class="card">
  <img src="/images/dfe.png" alt="DfE icon" class="dfe">
  <div class="card-text">
    <h2 class="govuk-heading-m">DfE</h2>
    <p class="govuk-body">
      3. Reviews the information supplied by the participant and tells them whether they are eligibile for funding.
      <br><br>
      4. Informs the chosen provider that the participant has submitted an application.
    </p>
  </div>
</div>

<div class="card">
  <img src="/images/provider.png" alt="Provider Icon" class="provider">
  <div class="card-text">
    <h2 class="govuk-heading-m">Provider</h2>
    <p class="govuk-body">5. Receives notification of registration and requests that the participant completes an application for their course.</p>
  </div>
</div>

<div class="card">
  <img src="/images/participant.png" alt="Participant Icon" class="participant">
  <div class="card-text">
    <h2 class="govuk-heading-m">Participant</h2>
    <p class="govuk-body">6. Completes and submits the application to their course provider.<br><br> 7. If they are suitable for the course, they’ll be accepted by the provider.</p>
  </div>
</div>

<br>

## Course preparation

<div class="card">
  <img src="/images/participant.png" alt="Participant Icon" class="participant">
  <div class="card-text">
    <h2 class="govuk-heading-m">Participant</h2>
    <p class="govuk-body">1. Finds course information and learns about the course details, structure, and expectations.</p>
  </div>
</div>

<div class="card">
  <img src="/images/provider.png" alt="Provider Icon" class="provider">
  <div class="card-text">
    <h2 class="govuk-heading-m">Provider</h2>
    <p class="govuk-body">2. Sends course logistics, including start date, session timings, and other key details. <br><br>3. Sends login details for the training platform.</p>
  </div>
</div>

<div class="card">
  <img src="/images/participant.png" alt="Participant Icon" class="participant">
  <div class="card-text">
    <h2 class="govuk-heading-m">Participant</h2>
    <p class="govuk-body">4. Accesses the training platform with the login details and begins engaging with course materials.</p>
  </div>
</div>

<br><br>

## Course introduction

<div class="card">
  <img src="/images/participant.png" alt="Participant Icon" class="participant">
  <div class="card-text">
    <h2 class="govuk-heading-m">Participant</h2>
    <p class="govuk-body">1. Attends the introduction session to get an overview of the course (often referred to as a ‘conference’).</p>
  </div>
</div>

<div class="card">
  <img src="/images/provider.png" alt="Provider Icon" class="provider">
  <div class="card-text">
    <h2 class="govuk-heading-m">Provider</h2>
    <p class="govuk-body">2. Delivers the introduction session, covering key course information and expectations.</p>
  </div>
</div>

<br><br>

## Start of course

<div class="card">
  <img src="/images/participant.png" alt="Participant Icon" class="participant">
  <div class="card-text">
    <h2 class="govuk-heading-m">Participant</h2>
    <p class="govuk-body">1. Starts the course and begins engaging with course content.</p>
  </div>
</div>

<div class="card">
  <img src="/images/provider.png" alt="Provider Icon" class="provider">
  <div class="card-text">
    <h2 class="govuk-heading-m">Provider</h2>
    <p class="govuk-body">2. Submits ‘Start’ declaration and confirms that the participant has started the course.</p>
  </div>
</div>

<div class="card">
  <img src="/images/api.png" alt="API Icon" class="api">
  <div class="card-text">
    <h2 class="govuk-heading-m">API endpoint</h2>
    <p class="govuk-body">3. Records that the participant has reached the start milestone and logs each milestone.</p>
  </div>
</div>

<div class="card">
  <img src="/images/dfe.png" alt="DfE Icon" class="dfe">
  <div class="card-text">
    <h2 class="govuk-heading-m">DfE</h2>
    <p class="govuk-body">4. Calculates payments and processes funding based on the ‘Start’ declaration.</p>
  </div>
</div>

<br>

## Updating participant info during the course

<div class="card">
  <img src="/images/participant.png" alt="Participant Icon" class="participant">
  <div class="card-text">
    <h2 class="govuk-heading-m">Participant</h2>
    <p class="govuk-body">1. Attends training sessions and takes part in scheduled course activities.</p>
  </div>
</div>

<div class="card">
  <img src="/images/provider.png" alt="Provider Icon" class="provider">
  <div class="card-text">
    <h2 class="govuk-heading-m">Provider</h2>
    <p class="govuk-body">2. Runs the course and delivers training sessions.<br><br> 3. Documents attendance, tracking who attended and when. <br><br> 4. Gathers assurance evidence such as proof of participation and progress.<br><br> 5. Submits milestone declarations to the API to confirm participant progress at key points.</p>
  </div>
</div>

<div class="card">
    <img src="/images/api.png" alt="API Icon" class="api">
    <div class="card-text">
      <h2 class="govuk-heading-m">API endpoint</h2>
      <p class="govuk-body">6. Sends milestone data to DfE to notify them of participant progress.</p>
    </div>
</div>

<div class="card">
  <img src="/images/dfe.png" alt="DfE Icon" class="dfe">
  <div class="card-text">
    <h2 class="govuk-heading-m">DfE</h2>
    <p class="govuk-body">7. Checks declarations and updates financial statements.</p>
  </div>
</div>

<div class="card">
  <img src="/images/api.png" alt="API Icon" class="api">
  <div class="card-text">
    <h2 class="govuk-heading-m">API endpoint</h2>
    <p class="govuk-body">8. Retrieves financial statements.<br><br> 9. Shares financial statements with provider to ensure transparency and accuracy.</p>
  </div>
</div>

<br><br>

## Payments process

This flow outlines how payments are managed between the provider and the Department for Education (DfE):

<div class="card">
  <img src="/images/provider.png" alt="Provider Icon" class="provider">
  <div class="card-text">
    <h2 class="govuk-heading-m">Provider </h2>
    <p class="govuk-body">1. Sends invoices to DfE for participant-related payments.</p>
  </div>
</div>

<div class="card">
  <img src="/images/dfe.png" alt="DfE Icon" class="dfe">
  <div class="card-text">
    <h2 class="govuk-heading-m">DfE </h2>
    <p class="govuk-body">2. Checks the submitted invoices for accuracy and eligibility.<br><br> 3. Sends output fees at each milestone.</p>
  </div>
</div>

<div class="card">
  <img src="/images/provider.png" alt="Provider Icon" class="provider">
  <div class="card-text">
    <h2 class="govuk-heading-m">Provider </h2>
    <p class="govuk-body">4. Receives output fees.</p>
  </div>
</div>

<!-- <div class="card"> -->
<!--   <img src="/images/dfe.png" alt="DfE Icon" class="dfe"> -->
<!--   <div class="card-text"> -->
<!--     <h2 class="govuk-heading-m">DfE </h2> -->
<!--     <p class="govuk-body">5. Sends a monthly service fee based on the target number of participants.</p> -->
<!--   </div> -->
<!-- </div> -->

<!-- <div class="card"> -->
<!--   <img src="/images/provider.png" alt="Provider Icon" class="provider"> -->
<!--   <div class="card-text"> -->
<!--     <h2 class="govuk-heading-m">Provider </h2> -->
<!--     <p class="govuk-body">6. Receives service fees.</p> -->
<!--   </div> -->
<!-- </div> -->
