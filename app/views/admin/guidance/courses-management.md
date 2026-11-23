# Courses management

Use **Settings** then **Manage courses frameworks** to see the courses in the service, the lead providers that deliver them and the contract details for each provider. Super admins can also add new courses and change a provider's delivery partners.

Only super admins can use this section. Other admin users do not see it.

## What you can do

- view the list of courses
- view one course, including its milestones and providers
- view a provider's contract details for a course
- change which delivery partners a provider can use for a course
- add a new course

## View the list of courses

1. Select **Settings**.
2. Select **course frameworks**.

The list shows each course's name and group. Select a course name to open it.

## View a course

The course page shows:

- **Identifier:** the unique code for the course
- **Group:** the group the course belongs to
- **Description:** a short description of the course

### Milestones

Milestones set when declarations can be sent for the course. The table shows:

- Declaration type
- Acceptance window start
- Acceptance window end
- Payment percentage. This shows "-" if the milestone has no payment percentage.

### Providers

The table lists the lead providers that deliver the course. Select **View details** to open a provider's contract details.

## View a provider's contract details

The page is called "[Provider name] contract details". It has 3 parts.

### Overview

The overview shows the lead provider name, the course name, the course URL and the contact email. It shows "-" if no URL or email is set.

### Contract details

This table shows the contract values for each [academic year](/admin/guidance/glossary#academic-year-registration-periods):

- Academic year
- Recruitment target
- Teacher funding

### Delivery partners

This lists the delivery partners the lead provider works with for this course. If there are none, the page shows "No delivery partners."

Lead providers can only record a delivery partner on a declaration if the partner is on this list.

## Change a provider's delivery partners

1. Open the provider's contract details page.
2. Under **Delivery partners**, select **Edit**.
3. Tick or untick delivery partners.
4. Select **save**.

The edit page shows 2 groups of delivery partners, each in alphabetical order:

- **Current delivery partners:** partners the provider uses now. These are ticked.
- **Other delivery partners:** all other partners in the service. These are not ticked.

### What ticking and unticking does

- **Ticking** a partner adds it for this provider and course. If the partner was removed before, this restores it.
- **Unticking** a partner removes it for this provider and course.

The change applies only to this provider and this course. It does not change the same partner for other providers or courses.

### What "removed" means

A removed delivery partner is archived. It is not deleted.

- It no longer shows in the admin console for this provider and course.
- It no longer shows in the lead provider API. The provider cannot choose it for new declarations.
- It is kept for audit.
- Declarations that already use the partner are not changed. They still show the partner's name.

To bring a partner back, tick it again in **Other delivery partners**.

### At least one delivery partner must stay

You cannot remove every delivery partner. If you untick them all and select **save**, the service shows "There is a problem" and "Select at least one delivery partner". Your ticks stay as you left them. Tick at least one partner and save again.

### After you save

The service returns to the provider's contract details page and shows how many delivery partners were added and removed, for example "1 delivery partner added, 0 removed".

## Add a new delivery partner

Use this when the partner is not in either group on the edit page.

1. Open the edit page.
2. Select **add new delivery partners**.
3. Enter the name in **Delivery partner name 1**.
4. To add more than one, select **add more**. A new empty box appears. The names you have already entered are kept. Nothing is saved yet.
5. Select **save**.

The service adds each new partner to the provider and course. It then shows how many were added.

If there is a problem, the service saves nothing and shows an error next to the name:

- **Enter a delivery partner name:** you left every box empty.
- **This delivery partner already exists, select it on the edit form instead:** a partner with that name is already in the service, whatever the capital letters. Go back and tick the partner on the edit page.
- **This delivery partner name is entered more than once:** you entered the same name twice. Remove or change one.

Spaces at the start and end of a name are ignored. Empty boxes are ignored if at least one other box has a name.

Select **Back** to return to the edit page.

## Unsaved changes warning

If you have ticked or unticked partners and then select **add new delivery partners**, the service shows "You have unsaved changes". It lists the "Delivery partners to add" and "Delivery partners to remove". Choose one of:

- **Save changes and continue:** saves your ticks and unticks, then opens the add page.
- **Discard changes and continue:** does not save your ticks and unticks, then opens the add page.
- **Go back:** returns to the edit page with your ticks and unticks still in place, so you can change them or save.

If you have not changed any ticks, the service opens the add page straight away.

## Who made a change

The service records every delivery partner change, including which admin made it. This covers adding, restoring and removing partners, and creating new ones. You cannot view this history in the admin console. Ask a developer if you need it.

## Add a new course

1. On the courses list, select **Add new course**.
2. Complete each step and select **Continue**. Select **Back** to return to an earlier step.
3. On **Check answers**, check the details. Select **Change** to correct a step.
4. Select **Create course**.

The service shows "Course created successfully".

The steps are:

1. **Course details:** name, course group, identifier, short code and description.
2. **Milestones:** the declaration types the course uses, with their acceptance windows and payment percentages.
3. **Lead providers:** the providers that deliver the course, with each one's URL and email.
4. **Contract financials:** teacher funding and recruitment target for each provider, by academic year. Select **Add academic year** to add another year, for example 2028.
5. **Delivery partners:** the delivery partners for each provider you chose.
6. **Check answers**

Name and course group are required, and you must choose at least one milestone.

To change delivery partners for a course that already exists, use the edit steps above, not the course builder.
