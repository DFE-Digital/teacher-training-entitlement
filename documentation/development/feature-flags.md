[< Back to Development overview](./overview.md)

# Feature Flags

Feature flags let you enable or disable behaviour without deploying code. The
service uses [Flipper](https://github.com/jnunemaker/flipper) backed by an
`active_record` adapter — flag state lives in the database, toggled at runtime.

---

## Current flags

All flags are registered in `FEATURE_FLAG_KEYS` inside
[`app/services/feature.rb`](../../app/services/feature.rb). New flags default to
**OFF** (see [Auto-initialization](#auto-initialization)).

| Flag key                                 | Purpose                                          | Toggle via                                        |
|------------------------------------------|--------------------------------------------------|---------------------------------------------------|
| `REGISTRATION_OPEN`                      | Opens registration to participants               | `Feature.registration_closed?(user)`              |
| `CLOSED_REGISTRATION_ENABLED`            | Post-registration features (re-opening, etc.)    | — (used directly)                                 |
| `MAINTENANCE_BANNER`                     | Shows/hides the yellow maintenance notice banner | `Feature.maintenance_banner_enabled?`             |
| `DFE_ANALYTICS_ENABLED`                  | Controls BigQuery event streaming                | `Feature.dfe_analytics_enabled?`                  |
| `LP_TRANSFERRED_DECLARATIONS_VISIBILITY` | Lets LPs see transferred declarations            | `Feature.lp_transferred_declarations_visibility?` |

`Feature` also exposes `disable_registration!` / `enable_registration!` for the
`REGISTRATION_DISABLED` flag.

---

## Admin UI

Super admins toggle flags at `/admin/features`. The page lists every flag, lets
you turn it on/off for everyone, and set per-actor overrides for individual
users. See [`../admin/overview.md`](../admin/overview.md) for the role model.

---

## Rails console

```ruby
Flipper.enable(Feature::MAINTENANCE_BANNER)        # on for everyone
Flipper.disable(Feature::MAINTENANCE_BANNER)       # off for everyone
Flipper.enabled?(Feature::REGISTRATION_OPEN)       # check state
Flipper.enable(Feature::REGISTRATION_OPEN, user)   # on for one user
```

> Use the flag's **string value** (the constant), not a symbol.

---

## Adding a new flag

1. Add its string key to `FEATURE_FLAG_KEYS` in `app/services/feature.rb`.
2. Add a class method to `Feature` that wraps `Flipper.enabled?`.
3. Use the method wherever the behaviour is gated.

```ruby
# Registration + wrapper (app/services/feature.rb)
NEW_FEATURE = "New feature".freeze
FEATURE_FLAG_KEYS = [NEW_FEATURE, ...].freeze

class << self
  def new_feature_enabled?
    Flipper.enabled?(NEW_FEATURE)
  end
end
```

```erb
<%# Usage in a view %>
<%= render "new_thing" if Feature.new_feature_enabled? %>
```

> **Do not** call `Flipper.enabled?` with a string literal outside of `Feature`.

---

## Auto-initialization

On every deploy `feature_flags:initialize` runs as an enhancement to
`db:migrate`. It adds any key in `FEATURE_FLAG_KEYS` not yet in the DB
(default: **OFF**) and removes any DB flag no longer in `FEATURE_FLAG_KEYS`.

See [`lib/tasks/initialize_feature_flags.rake`](../../lib/tasks/initialize_feature_flags.rake)
for the implementation.

---

## Testing

`REGISTRATION_OPEN` is enabled globally in `spec/rails_helper.rb`:

```ruby
config.before { Flipper.enable(Feature::REGISTRATION_OPEN) }
```

Toggle flags per-spec with `Flipper.enable/disable` in `before` blocks:

```ruby
before { Flipper.enable(Feature::MAINTENANCE_BANNER) }

it "shows the banner" do
  visit "/"
  expect(page).to have_css(".govuk-notification-banner")
end
```

`Feature` class methods delegate to Flipper, so they work in tests without
stubbing. Flags use the same `active_record` adapter — no test double.

> **Tip:** toggle only what your spec needs. Do not blanket-reset flags; the
> `REGISTRATION_OPEN` pre-enable is the only global default.

---

## Per-user flags

Pass a user object to `Flipper.enabled?` for per-actor gates:

```ruby
Flipper.enabled?(:flag, current_user)
```

On first authentication the participant's `feature_flag_id` cookie value is
stored on their `User` record. `User#flipper_id` returns this value. Per-actor
overrides can also be set from `/admin/features` by entering the user's
`flipper_id`.

In `config/environments/production.rb` the actor limit is raised to 1000:

```ruby
config.flipper.actor_limit = 1000
```

---

## Override pattern (opt-out)

Flipper cannot disable a flag for one user when it is enabled for **everyone**
("everyone" is a group, and groups have no individual exceptions). Use **two
flags** — one to enable, one to override:

```ruby
def user_in_pilot?(user)
  Flipper.enabled?(:feature_pilot, user) &&
    !Flipper.enabled?(:removed_from_feature_pilot, user)
end
```

Enable `feature_pilot` for everyone. Enable `removed_from_feature_pilot` for
the specific user(s) to exclude.

---

## Key files

| File                                           | Purpose                               |
|------------------------------------------------|---------------------------------------|
| `app/services/feature.rb`                      | Key registry + wrapper methods        |
| `lib/tasks/initialize_feature_flags.rake`      | Auto-initialisation on deploy         |
| `config/environments/production.rb`            | Flipper actor limit                   |
| `config/routes/admin.rb`                       | `/admin/features` routes              |
| `app/controllers/admin/features_controller.rb` | Admin UI controller                   |
| `spec/rails_helper.rb`                         | Global `REGISTRATION_OPEN` pre-enable |
| `app/models/user.rb`                           | `flipper_id` for per-actor gates      |

---

## Related docs

- [Development overview](./overview.md) — tech stack, local setup, CI pipeline
- [Admin console overview](../admin/overview.md) — role model, feature flag page
- [DfE Analytics](../monitoring/analytics.md) — BigQuery flow gated by `DFE_ANALYTICS_ENABLED`
