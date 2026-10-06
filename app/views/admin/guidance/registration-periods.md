# Registration period

A registration period sets when people can register for courses, and which courses they can register for. It is also called a cohort in some parts of the service and in the API.

This page explains what registration periods are for, how to manage them, and who can do what.

## What registration periods are for

A registration period is a window of time. Each one has a registration start date and an optional end date. Registration for the courses in the period opens on the start date.

Each registration period also has:

- a description, which is its name across the service
- an [academic year](/admin/guidance/glossary#academic-year-registration-periods)

More than one registration period can have the same academic year. For example, you can have one for the autumn and one for the spring.

### How registration periods connect to other things

- **Courses.** You add courses to a registration period.
- **Applications.** Every [application](/admin/guidance/glossary#application) belongs to one course in one registration period.

### How the dates affect registration

A registration period is open when today is on or after the registration start date. It stays open until the end date. If there is no end date, it stays open.

- People can only choose a start date from courses in an open registration period.
- If no registration period is open, people see the registration closed page.
- The "Registration open" feature flag can also close registration, whatever the dates.
- On the registration start date, people who registered their interest get an email.
- The day after the registration start date, participants who deferred a course that is in the period get an email.

## How to manage registration periods

Select **Registration periods** in the main navigation to start.

### View the registration periods

The list shows the newest registration start date first. It has these columns:

- Description
- Registration open
- Registration start date
- Registration end date

### View one registration period

1. Select **Registration periods**.
2. Select the description of the registration period.

The page shows the name, the academic year and the registration start date. It also lists the courses in the period. The registration end date shows in the list only.

To see the details of a course in the period, select the course name. You can also find courses under **Courses** in the main navigation.

### Create a registration period

Only super admins can do this.

1. Select **Registration periods**.
2. Select **New registration period**.
3. Fill in the form.
4. Select **Create cohort**.

The service shows "Registration period created".

- **Description:** A name of 5 to 50 characters. It must be different from every other description, ignoring capital letters. If you leave it blank, the service uses the month and year of the start date, for example "April 2026".
- **Academic year:** The year the period starts, from 2021 to 2034.
- **Registration start date:** Required. Only one registration period can start in the same month and year.
- **Registration end date:** Optional. Leave it blank for no end date.

The service does not check that the end date is after the start date, or that the academic year matches the start date. Check these yourself.

Creating a registration period does not open registration. Add courses to it first.

### Edit a registration period

Only super admins can do this. The glossary calls it [Edit details (registration periods)](/admin/guidance/glossary#edit-details-registration-periods).

1. Open the registration period.
2. Select **Edit cohort details**.
3. Change the fields. The rules are the same as for creating one, except the description cannot be blank.
4. Select **Update cohort**.

The service shows "Registration period updated".

Changing the registration start date changes when the period opens. It also changes when the emails go out.

If you change the academic year of a registration period that already has courses, the courses keep the old academic year. The service then shows errors when it next saves those courses. Ask a developer to help.

### Delete a registration period

Only super admins can do this. The glossary calls it [Remove (registration periods)](/admin/guidance/glossary#remove-registration-periods). You cannot restore a deleted registration period.

1. Open the registration period.
2. Select **Delete cohort**.
3. Read the warning, then select **Confirm delete cohort**. Select **Cancel** to keep the period.

The service shows "Registration period deleted".

Deleting a registration period also removes its courses from the period, with their lead provider contracts and delivery partnerships. The courses themselves stay in the service.

The service does not stop you deleting a registration period that has applications. Do not do this. The applications stay in the service but no longer have a valid course or registration period.

### Add a course to a registration period

Only super admins can do this.

1. Open the registration period.
2. Select **Add course to cohort**.
3. Choose the course. The list only shows courses that are not yet in the period.
4. Enter the date in **Training starts at**.
5. Select **Add course**.

The service shows "Course added to registration period".

The service then:

- sets the course's academic year from the registration period
- sets the term from the registration start month: autumn for September to December, spring for January to April, and summer for May to August
- copies the teacher funding and recruitment target for each lead provider from the course's standard contract
- adds each lead provider's delivery partners

To add providers to a course or update their contracts, open the course from the registration period and select **Add/Remove providers**. Only super admins can do this.

### Move an application to a different registration period

All admin users can do this.

1. Open the application.
2. Find **Schedule cohort** and select **Change**.
3. Choose a registration period. The list only shows other periods that include the same course.
4. Select **Continue**.

You cannot move an application that has declarations.

## Who can do what

All admin users can sign in to the admin console and see this guidance. There are two types of admin user: admin and super admin. The code does not give the support, contract management, finance and assurance teams different permissions. Their access depends only on whether they are a super admin.

<table class="govuk-table">
  <caption class="govuk-table__caption govuk-table__caption--m">Registration period actions by admin user type</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Action</th>
      <th scope="col" class="govuk-table__header">Admin</th>
      <th scope="col" class="govuk-table__header">Super admin</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <td class="govuk-table__cell">View the list of registration periods</td>
      <td class="govuk-table__cell">Yes</td>
      <td class="govuk-table__cell">Yes</td>
    </tr>
    <tr class="govuk-table__row">
      <td class="govuk-table__cell">View one registration period and its courses</td>
      <td class="govuk-table__cell">Yes</td>
      <td class="govuk-table__cell">Yes</td>
    </tr>
    <tr class="govuk-table__row">
      <td class="govuk-table__cell">View course details in a registration period</td>
      <td class="govuk-table__cell">Yes</td>
      <td class="govuk-table__cell">Yes</td>
    </tr>
    <tr class="govuk-table__row">
      <td class="govuk-table__cell">Move an application to a different registration period</td>
      <td class="govuk-table__cell">Yes</td>
      <td class="govuk-table__cell">Yes</td>
    </tr>
    <tr class="govuk-table__row">
      <td class="govuk-table__cell">Create a registration period</td>
      <td class="govuk-table__cell">No</td>
      <td class="govuk-table__cell">Yes</td>
    </tr>
    <tr class="govuk-table__row">
      <td class="govuk-table__cell">Edit a registration period</td>
      <td class="govuk-table__cell">No</td>
      <td class="govuk-table__cell">Yes</td>
    </tr>
    <tr class="govuk-table__row">
      <td class="govuk-table__cell">Delete a registration period</td>
      <td class="govuk-table__cell">No</td>
      <td class="govuk-table__cell">Yes</td>
    </tr>
    <tr class="govuk-table__row">
      <td class="govuk-table__cell">Add a course to a registration period</td>
      <td class="govuk-table__cell">No</td>
      <td class="govuk-table__cell">Yes</td>
    </tr>
    <tr class="govuk-table__row">
      <td class="govuk-table__cell">Use Add/Remove providers on a course</td>
      <td class="govuk-table__cell">No</td>
      <td class="govuk-table__cell">Yes</td>
    </tr>
  </tbody>
</table>

Admin users do not see the buttons they cannot use. If an admin opens one of those pages by its web address, the service sends them to the sign-in page with the message "Unauthorized".

A super admin can give another admin super admin access. Go to **Settings**, then **Admins**, then select **Make Super Admin**.

## Related terms

See the [glossary](/admin/guidance/glossary) for [registration periods](/admin/guidance/glossary#registration-periods), [academic year](/admin/guidance/glossary#academic-year-registration-periods) and [registration start date](/admin/guidance/glossary#registration-start-date).
