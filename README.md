# AdvancedSelect

AdvancedSelect is a small Rails engine for rendering an advanced select input with Rails partials, Stimulus behavior, plain CSS, and i18n defaults.

## Contents

- [Design Principles](#design-principles)
- [Requirements](#requirements)
- [Limitations](#limitations)
- [Usage](#usage)
- [Supported Rails Setups](#supported-rails-setups)
- [JavaScript](#javascript)
- [Stimulus Customization](#stimulus-customization)
- [jsbundling/Propshaft Example](#jsbundlingpropshaft-example)
- [CSS And Asset Pipeline](#css-and-asset-pipeline)
- [Basic Local Select](#basic-local-select)
- [Remote Search](#remote-search)
- [Multiple Select](#multiple-select)
- [Add Mode](#add-mode)
- [Dependent Fields](#dependent-fields)
- [Custom Option Content](#custom-option-content)
- [Option Contract](#option-contract)
- [API Reference](#api-reference)
- [Local Development](#local-development)
- [i18n](#i18n)
- [Styling](#styling)
- [Contributing](#contributing)
- [License](#license)

## Design Principles

AdvancedSelect is intentionally lightweight. It owns the reusable UI contract, not the host application's data or business rules.

The gem owns:

- Rails helper and partial rendering.
- Option HTML structure.
- Stimulus dropdown behavior.
- Plain CSS defaults.
- i18n defaults.
- Optional generators for installation and custom option content.

The host Rails app owns:

- Routes.
- Controllers.
- Database queries.
- Authorization.
- Filtering and sorting.
- Turbo Stream endpoints.
- Domain-specific option formatting.

Remote options are Rails/Turbo driven. The Stimulus controller sends UI state such as `query`, `selected_id`, `selected_ids[]`, `add_mode`, and dependent field values to the host endpoint. The endpoint returns server-rendered Turbo Stream HTML, and Turbo replaces the option list.

Stimulus does not know about models, database tables, authorization, or business workflows. This keeps the gem small, reusable, and easy to integrate into different Rails apps.

## Requirements

- Ruby `>= 3.1`
- Rails `>= 7.1`
- `turbo-rails >= 2.0`
- `stimulus-rails >= 1.3`
- A Rails asset setup that can load plain CSS

Supported asset setups are listed below.

## Limitations

AdvancedSelect does not provide backend endpoints. The host app must define routes and controller actions for remote option loading.

AdvancedSelect does not provide query objects, model concerns, authorization logic, filtering logic, or database integrations. It only renders the select UI and sends UI state to the host app's Turbo endpoint.

## Usage

Add the gem to the host Rails app:

```ruby
gem "advanced_select", git: "https://github.com/MehmetCelik4/advanced_select.git"
```

Run the installer:

```bash
bin/rails generate advanced_select:install
```

The default setup is `importmap`. For ivdIQ-style apps that use `jsbundling-rails`, pass the setup explicitly:

```bash
bin/rails generate advanced_select:install --setup=importmap
bin/rails generate advanced_select:install --setup=jsbundling
```

Or use the Rake shortcut:

```bash
bin/rails advanced_select:install
```

The Rake shortcut accepts the same setup choice through an environment variable:

```bash
SETUP=jsbundling bin/rails advanced_select:install
```

For the default `importmap` setup, the installer registers the engine Stimulus controller and wires the engine assets:

```text
config/importmap.rb
app/javascript/controllers/index.js
app/assets/stylesheets/application.css
```

The installer currently supports two setup modes:

- `--setup=importmap`: pins the engine controller, registers it in `app/javascript/controllers/index.js`, and requires the engine stylesheet from `app/assets/stylesheets/application.css`.
- `--setup=jsbundling`: copies the files, registers the controller in `app/javascript/controllers/index.js`, and imports the stylesheet from `app/assets/stylesheets/application.postcss.css`.

Other asset layouts can still use the copied files manually. Installer support for those layouts can be added later as separate, tested setup modes.

## Supported Rails Setups

AdvancedSelect expects a Rails app with Turbo and Stimulus available. The gem depends on `railties`, `actionview`, `turbo-rails`, and `stimulus-rails`; it does not depend on the full `rails` gem or on Active Record.

### JavaScript

Supported:

- `importmap-rails` with `stimulus-rails`
- `jsbundling-rails` or another bundler with manual Stimulus registration

The host app must load Turbo and start Stimulus. AdvancedSelect depends on `turbo-rails` and `stimulus-rails`, but the app still owns its JavaScript entrypoint.

The installer adds an explicit registration to `app/javascript/controllers/index.js`:

```js
import AdvancedSelectController from "advanced_select/advanced_select_controller"
application.register("advanced-select", AdvancedSelectController)
```

The installer also pins the engine controller:

```ruby
pin "advanced_select/advanced_select_controller", to: "advanced_select/advanced_select_controller.js"
```

The engine exposes `advanced_select/advanced_select_controller.js` to the asset pipeline, so host apps should not need to add `AdvancedSelect::Engine.root.join("app/javascript")` to `config.assets.paths` or link the controller from `app/assets/config/manifest.js`.

Importmap apps should already have a Stimulus entrypoint with an exported `application`, similar to this:

```js
// app/javascript/controllers/index.js
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

eagerLoadControllersFrom("controllers", application)
```

If the host app does not use the standard `stimulus-rails` entrypoint, register the engine controller manually:

```js
import AdvancedSelectController from "advanced_select/advanced_select_controller"

application.register("advanced-select", AdvancedSelectController)
```

For `jsbundling-rails`, the installer registers the copied controller in the manifest-style Stimulus entrypoint. It expects `app/javascript/controllers/index.js` to follow the shape generated by `stimulus-rails`, for example:

```js
import { application } from "./application"

import ExistingController from "./existing_controller"
application.register("existing", ExistingController)
```

Other bundlers can use the copied controller manually, but the installer currently only patches the `jsbundling-rails` manifest shape.

The installed controller imports `Turbo` from `@hotwired/turbo-rails`, so the host app must have `@hotwired/turbo-rails` resolvable in its importmap or bundler setup.

### Stimulus Customization

For importmap apps, customize behavior only when the host app needs it. Add a local subclass:

```js
// app/javascript/controllers/advanced_select_controller.js
import AdvancedSelectController from "advanced_select/advanced_select_controller"

export default class extends AdvancedSelectController {
  displayLabel(option) {
    return super.displayLabel(option).trim()
  }
}
```

Then change the registration in `app/javascript/controllers/index.js` to import the local subclass:

```js
import AdvancedSelectController from "./advanced_select_controller"
application.register("advanced-select", AdvancedSelectController)
```

This keeps local custom behavior small while allowing future gem fixes to flow through the base controller.

For `jsbundling-rails` and other bundlers, the installer copies the full controller because bundlers do not resolve Rails engine JavaScript assets automatically. In that setup the copied file is host-owned.

### jsbundling/Propshaft Example

Apps like ivdIQ use Rails with `jsbundling-rails`, esbuild, Propshaft, and a PostCSS entrypoint. In that setup the installer is expected to leave these changes:

```bash
bin/rails generate advanced_select:install --setup=jsbundling
```

```js
// app/javascript/controllers/index.js
import AdvancedSelectController from "./advanced_select_controller"
application.register("advanced-select", AdvancedSelectController)
```

```css
/* app/assets/stylesheets/application.postcss.css */
@import "advanced_select.css";
```

Then rebuild the host app's JavaScript and CSS assets. The exact commands are app-specific:

```bash
yarn build
yarn build:css
```

### CSS And Asset Pipeline

For importmap apps, the installer uses the engine stylesheet directly. It adds this Sprockets require to `app/assets/stylesheets/application.css`:

```css
/*
 *= require advanced_select/advanced_select
 *= require_tree .
 *= require_self
 */
```

When `require_tree .` is present, the installer places the engine stylesheet before it. If the host app needs app-specific styling, create a stylesheet such as `app/assets/stylesheets/advanced_select_overrides.css`; `require_tree .` will load it after the gem defaults.

If the host app loads a separate Tailwind bundle and keeps component overrides in Tailwind files, keep the gem CSS in `application.css` and load Tailwind after it in the layout:

```erb
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
```

With that order, Tailwind component files such as `app/assets/tailwind/components/forms.css` load after the gem defaults and can override them with `@apply`:

```css
.ui-advanced-select-trigger {
  @apply flex min-h-10 w-full items-center justify-between;
}
```

Do not also import or require `advanced_select/advanced_select` from the Tailwind bundle in that setup; load the gem CSS once through `application.css`.

For `--setup=jsbundling`, the installer copies plain CSS to:

```text
app/assets/stylesheets/advanced_select.css
```

Then it imports the copied file from:

```css
/* app/assets/stylesheets/application.postcss.css */
@import "advanced_select.css";
```

For `--setup=importmap`, the installer checks `app/assets/stylesheets/application.css`:

- If it is a Sprockets-style manifest, the installer normalizes the AdvancedSelect require before `require_tree .` when that directive is present, otherwise before `require_self`.
- If `advanced_select/advanced_select` already exists, the installer does not add duplicates.

```css
/*
 *= require advanced_select/advanced_select
 */
```

The installer does not create a host override stylesheet. Create one only when the app needs it:

```text
app/assets/stylesheets/advanced_select_overrides.css
```

Use plain CSS in that file. Do not use Tailwind `@apply` there unless your host app explicitly processes Sprockets stylesheets through Tailwind.

If the installer cannot safely detect the stylesheet entrypoint, require `advanced_select/advanced_select` through the host app's asset setup.

If the host app uses plain Propshaft stylesheet links or another CSS pipeline, wire the engine stylesheet manually for now. Those layouts are intentionally not installer modes yet.

Sprockets-style manual example:

```css
/*
 *= require advanced_select/advanced_select
 *= require_tree .
 *= require_self
 */
```

### Basic Local Select

Use local options when the complete option list is already available while rendering the page:

```erb
<%= advanced_select_tag(
  "record[item_id]",
  id: "record_item_id",
  selected: selected_option,
  options: options,
  placeholder: t(".item_placeholder"),
  searchable: false
) %>
```

Options are hashes:

```ruby
options = [
  { id: "item-1", label: "Item one" },
  { id: "item-2", label: "Item two", description: "Optional secondary text" }
]

selected_option = { id: "item-1", label: "Item one" }
```

### Remote Search

Use `options_url` when options should be loaded from a host app endpoint:

```erb
<%= advanced_select_tag(
  "record[item_id]",
  id: "record_item_id",
  selected: selected_option,
  options: [],
  placeholder: t(".item_placeholder"),
  options_url: item_options_path
) %>
```

The endpoint should return a Turbo Stream that replaces the options target:

```erb
<%= turbo_stream.replace params[:target] do %>
  <%= advanced_select_options_tag(
    target_id: params[:target],
    selected: selected_options,
    options: options,
    query: params[:query]
  ) %>
<% end %>
```

If the endpoint action does not use Rails' normal Turbo Stream negotiation, render the format explicitly:

```ruby
def options
  @target_id = params.fetch(:target)
  @options = load_options

  render formats: :turbo_stream
end
```

The Stimulus controller sends these query params when loading remote options:

- `target`: DOM id to replace with the returned options HTML.
- `query`: current search text.
- `selected_id`: current single selected id when opening a selected remote field.
- `selected_ids[]`: all selected ids.
- `add_mode`: `"1"` when add mode is enabled, otherwise `"0"`.
- each `dependent_fields` entry, using the configured param name.

### Multiple Select

Set `multiple: true` and use an array-style form field name:

```erb
<%= advanced_select_tag(
  "record[item_ids][]",
  id: "record_item_ids",
  selected: selected_options,
  options: options,
  placeholder: t(".items_placeholder"),
  multiple: true,
  searchable: false
) %>
```

For remote multiple options, pass `multiple: true` to the options render too:

```erb
<%= advanced_select_options_tag(
  target_id: params[:target],
  selected: selected_options,
  options: options,
  multiple: true,
  query: params[:query]
) %>
```

### Add Mode

Set `add_mode: true` when users may submit a new typed value:

```erb
<%= advanced_select_tag(
  "record[tags][]",
  id: "record_tags",
  selected: selected_tags,
  options: [],
  placeholder: t(".tags_placeholder"),
  options_url: tag_options_path,
  multiple: true,
  add_mode: true
) %>
```

New values submit with the `__new__:` prefix:

```text
__new__:New tag
```

### Dependent Fields

Use `dependent_fields` when a remote option endpoint depends on another field value:

```erb
<%= select_tag "record[parent_id]", options_for_select(parent_options), id: "record_parent_id" %>

<%= advanced_select_tag(
  "record[item_id]",
  id: "record_item_id",
  selected: selected_option,
  options: [],
  placeholder: t(".item_placeholder"),
  options_url: item_options_path,
  dependent_fields: { parent_id: "#record_parent_id" }
) %>
```

The remote request will include `parent_id=<current field value>`.

### Custom Option Content

Use a custom option content partial when an option needs richer content. The engine still renders the option button, Stimulus data attributes, and ARIA attributes:

```bash
bin/rails generate advanced_select:option_content products
```

This creates:

```text
app/views/advanced_select/option_contents/_products.html.erb
```

The partial receives one local:

```erb
<%# locals: (option:) %>

<span class="ui-advanced-select-option-content">
  <span><%= option.fetch(:code) %></span>
  <span><%= option.fetch(:label) %></span>
  <% if option[:description].present? %>
    <span class="ui-advanced-select-option-description"><%= option[:description] %></span>
  <% end %>
</span>
```

The host app can pass any custom keys inside each option hash:

```ruby
product_options = [
  {
    id: product.id,
    value: product.id,
    label: product.name,
    display_label: product.name,
    description: product.category_name,
    code: product.code
  }
]
```

Pass the partial path to the select:

```erb
<%= advanced_select_tag(
  "record[product_id]",
  id: "record_product_id",
  selected: selected_product,
  options: product_options,
  placeholder: t(".product_placeholder"),
  options_url: product_options_path,
  option_content_partial: "advanced_select/option_contents/products"
) %>
```

Use the same partial when rendering remote options:

```erb
<%= turbo_stream.replace params[:target] do %>
  <%= advanced_select_options_tag(
    target_id: params[:target],
    selected: selected_options,
    options: options,
    multiple: false,
    add_mode: params[:add_mode] == "1",
    query: params[:query],
    option_content_partial: "advanced_select/option_contents/products"
  ) %>
<% end %>
```

### Option Contract

Each option must include `id`. Other keys are optional:

```ruby
{
  id: "row-7",
  value: "submitted-value",
  label: "Parent > Child",
  display_label: "Child",
  description: "Optional secondary text"
}
```

- `id` is the stable selection identity.
- `value` is submitted in the hidden input. If omitted, `id` is submitted.
- `label` is the full option label.
- `display_label` is used in the selected summary. If omitted, the helper derives it from `label`.
- `description` is rendered by the default option content partial.

Grouped options use this shape:

```ruby
[
  {
    label: "Recent",
    options: [
      { id: "recent-1", label: "Recent item" }
    ]
  },
  {
    label: "All",
    options: [
      { id: "all-1", label: "All item" }
    ]
  }
]
```

### API Reference

`advanced_select_tag`:

```ruby
advanced_select_tag(
  name,
  id:,
  selected:,
  options:,
  placeholder:,
  options_url: nil,
  multiple: false,
  searchable: true,
  add_mode: false,
  dependent_fields: {},
  option_content_partial: nil,
  classes: {},
  append_classes: {}
)
```

`advanced_select_options_tag`:

```ruby
advanced_select_options_tag(
  target_id:,
  selected:,
  options:,
  multiple: false,
  add_mode: false,
  query: nil,
  option_content_partial: nil,
  classes: {},
  append_classes: {}
)
```

For importmap/Sprockets apps, require `advanced_select/advanced_select` from your stylesheet manifest before host app styles. For jsbundling apps, include the copied `app/assets/stylesheets/advanced_select.css` after your base styles.

## Local Development

This repo includes a committed local Nix flake for isolated development and testing. It pins the shell to the gem's own `Gemfile`, local bundle path, Ruby, Node, esbuild, and Playwright browsers:

```bash
nix develop
bundle install
bin/rails test test/advanced_select/test.rb
bin/rails test test/helpers/advanced_select/helper_test.rb
bin/rails test test/system/advanced_select_interaction_test.rb
bin/rails test test/system/jsbundling_advanced_select_interaction_test.rb
```

With direnv enabled, `.envrc` loads the flake and adds `bin/` to `PATH`, so the same commands can be shortened further:

```bash
rails test test/helpers/advanced_select/helper_test.rb
```

The system tests use Capybara with Playwright against two dummy Rails apps:

- `test/dummy` covers the importmap setup.
- `test/dummy_jsbundling` covers a jsbundling/Propshaft setup with an esbuild-built JavaScript and CSS bundle.

Both browser tests verify local selection, remote Turbo Stream option replacement, stylesheet loading, and hidden input updates.

If you do not use Nix, provide equivalent local Ruby, Bundler, Node, esbuild, and Playwright browser dependencies before running the browser/system tests.

### i18n

Default locale keys:

```yaml
shared:
  advanced_select:
    add_option: "Add %{query}"
    empty: "No options found"
    error: "Options could not be loaded"
    loading: "Loading..."
```

Override these keys in the host app as needed.

## Styling

AdvancedSelect ships plain CSS defaults. When no `classes:` map is provided, rendered elements use the public `ui-advanced-select-*` styling classes.

### Styling With Tailwind Classes

Host apps can pass a `classes:` map to replace the default styling class for each mapped element. This is useful for option rows where the gem's default hover or selected styles should not compete with host Tailwind classes.

Use `append_classes:` when the host app wants to keep the gem's structural defaults and add small adjustments to the end of the class list. This is usually better for structural elements such as `trigger`, `dropdown`, `summary`, and `search`.

```erb
<%= advanced_select_tag(
  "cost_allocation[customer_type]",
  id: "cost_allocation_customer_type",
  selected: selected_customer_type,
  options: customer_type_options,
  placeholder: "Customer type",
  classes: {
    option: "flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-gray-700 hover:bg-red-500 hover:text-white",
    option_active: "bg-red-500 text-white",
    option_selected: "bg-indigo-50 text-indigo-700"
  },
  append_classes: {
    trigger: "min-h-10 rounded-md border-gray-300"
  }
) %>
```

Class map values replace defaults per key; they are not appended to the default styling class. For example, if `classes[:option]` is present, option buttons use only that class string and do not also include `.ui-advanced-select-option`. Keys that are not present still use their default classes. `append_classes:` values append after the resolved class for the same key. For example, `append_classes[:trigger]` renders `.ui-advanced-select-trigger` followed by the host classes.

Use `option_active` for hover and keyboard active state. Stimulus adds and removes those classes as the active option changes. Use `add_option_active` when add-mode rows need a different active state. Use `option_selected` for selected state; it is rendered on initially selected options and updated by Stimulus when selection changes. `aria-selected="true"` is still preserved.

Supported `classes:` and `append_classes:` keys:

```ruby
classes: {
  root: "...",
  trigger: "...",
  summary: "...",
  placeholder: "...",
  value: "...",
  token: "...",
  caret: "...",
  clear: "...",
  dropdown: "...",
  search: "...",
  options: "...",
  option: "...",
  option_active: "...",
  option_selected: "...",
  option_check: "...",
  option_content: "...",
  option_description: "...",
  group_label: "...",
  add_option: "...",
  add_option_active: "...",
  empty: "...",
  loading: "...",
  error: "..."
}
```

For remote Turbo Stream option replacement, pass the same class map to `advanced_select_options_tag` in the endpoint template when server-rendered option rows should include the host classes:

```erb
<%= advanced_select_options_tag(
  target_id: @target_id,
  selected: @selected_options,
  options: @options,
  classes: advanced_select_classes,
  append_classes: advanced_select_append_classes
) %>
```

Tailwind content scanning can usually see class strings when they are written literally in ERB. If the host app builds class names dynamically, add the relevant classes to the app's Tailwind safelist.

The host app can still load the gem CSS through `application.css`. `classes:` entries replace the mapped default classes for that helper call; unmapped keys keep the gem defaults. `append_classes:` entries keep the resolved class and append host classes after it.

### CSS Overrides

Importmap/Sprockets host applications can put app-specific styling in a host-owned file such as:

```text
app/assets/stylesheets/advanced_select_overrides.css
```

The installer does not create this file. Create it only when the host app needs Sprockets-side overrides. With the default Sprockets manifest, `require_tree .` loads it after `advanced_select/advanced_select`, so app-specific styles can override the gem defaults. Keep it as plain CSS so gem updates stay clean.

Tailwind apps can keep AdvancedSelect overrides in an existing Tailwind component file such as `app/assets/tailwind/components/forms.css`. In that case, load the host layout's `application` stylesheet before `tailwind` so the Tailwind bundle wins:

```erb
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
```

Example Tailwind override:

```css
.ui-advanced-select-trigger {
  @apply flex min-h-10 w-full items-center justify-between rounded-md;
}
```

For jsbundling apps, override after the copied `app/assets/stylesheets/advanced_select.css`.

Common styling hooks:

- `.ui-advanced-select-trigger` controls the visible input button, border, radius, height, background, and focus outline.
- `.ui-advanced-select-dropdown` controls the popup container, border, radius, shadow, width, and `z-index`.
- `.ui-advanced-select-options` controls the scroll container and default `max-height`.
- `.ui-advanced-select-option` controls option row spacing, hover state, and font sizing.
- `.ui-advanced-select-option[aria-selected="true"]` controls selected option colors.
- `.ui-advanced-select-token` controls multiple-select token styling.
- `.ui-advanced-select-add-option` controls add-mode row styling.
- `.ui-advanced-select-empty`, `.ui-advanced-select-loading`, and `.ui-advanced-select-error` control state message styling.

Example host override:

```css
.ui-advanced-select-trigger {
  border-color: var(--field-border);
  border-radius: 0.5rem;
}

.ui-advanced-select-option[aria-selected="true"] {
  background: var(--selected-bg);
  color: var(--selected-text);
}
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
