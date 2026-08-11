# SimpleGUI (`simple_gg`) Example Demos & Screenshots

This directory contains beginner-friendly, well-commented examples demonstrating the entire `simplegui` cross-platform API built on V's `gg` graphics module.

---

## 🎨 Visual Showcase & Snapshots

```carousel
![01 - Quickstart Demo](../snapshots/ex1.png)
<!-- slide -->
![02 - Theme Gallery Demo](../snapshots/ex2.png)
<!-- slide -->
![03 - Layout Containers Demo](../snapshots/ex3.png)
<!-- slide -->
![04 - Component Gallery Demo](../snapshots/ex4.png)
<!-- slide -->
![05 - Nameless Shortcuts Demo](../snapshots/ex5.png)
<!-- slide -->
![06 - Interactive Dashboard Demo](../snapshots/ex6.png)
<!-- slide -->
![07 - Advanced Controls Demo](../snapshots/ex7.png)
<!-- slide -->
![08 - RAD Application Builder Demo](../snapshots/ex8.png)
<!-- slide -->
![09 - Control Customization & Geometry Demo](../snapshots/ex9.png)
<!-- slide -->
![10 - More Window UI Controls Demo](../snapshots/ex10.png)
<!-- slide -->
![12 - System & Stdlib Toolkit Demo](../snapshots/ex12.png)
<!-- slide -->
![13 - Reactive State Store Demo](../snapshots/ex13.png)
```

---

## 📁 Examples Included

| Example File                                                           | Description                      | Features Covered                                                                                                                                          | Snapshot                               |
| :--------------------------------------------------------------------- | :------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------- |
| **[`01_quickstart.v`](01_quickstart.v)**                               | Beginner starter app             | Window creation, theme, form fields, checkbox, buttons, click callbacks.                                                                                  | ![Snapshot 01](../snapshots/ex1.png)   |
| **[`02_theme_gallery.v`](02_theme_gallery.v)**                         | Theme gallery & switcher         | Live dropdown selector to switch themes dynamically across 17 production palettes.                                                                        | ![Snapshot 02](../snapshots/ex2.png)   |
| **[`03_layout_containers.v`](03_layout_containers.v)**                 | Layout & Group containers        | Horizontal rows (`begin_row`), multi-column grids (`begin_grid`), and group cards.                                                                        | ![Snapshot 03](../snapshots/ex3.png)   |
| **[`04_widgets_and_forms.v`](04_widgets_and_forms.v)**                 | Form component gallery           | Form inputs, password field, number stepper, range slider, toggle switch, rating stars, date picker, progress bar, metric cards, alert banner.            | ![Snapshot 04](../snapshots/ex4.png)   |
| **[`05_nameless_shortcuts.v`](05_nameless_shortcuts.v)**               | Rapid prototyping                | Nameless control shortcuts (`win.input()`, `win.checkbox()`, `win.number()`, `win.button()`).                                                             | ![Snapshot 05](../snapshots/ex5.png)   |
| **[`06_dashboard_app.v`](06_dashboard_app.v)**                         | Interactive dashboard app        | Multi-column metric KPI cards, polyline trend charts, environment settings, region dropdown, deployment callbacks.                                        | ![Snapshot 06](../snapshots/ex6.png)   |
| **[`07_advanced_controls.v`](07_advanced_controls.v)**                 | Advanced UI controls & shortcuts | Data tables, tab containers, tree views, search bar, breadcrumbs, avatars, status badges, accordions, and window close hooks.                             | ![Snapshot 07](../snapshots/ex7.png)   |
| **[`08_rad_development.v`](08_rad_development.v)**                     | RAD application builder          | Batch field reading/clearing, JSON export, control enable/disable, OS notifications, clipboard access, and native confirm boxes.                          | ![Snapshot 08](../snapshots/ex8.png)   |
| **[`09_control_customization.v`](09_control_customization.v)**         | Control customization & geometry | Explicit sizing, padding/margins, custom font sizes/colors/borders, corner radius, tooltips, and fluent `win.control()` chaining.                         | ![Snapshot 09](../snapshots/ex9.png)   |
| **[`10_more_controls.v`](10_more_controls.v)**                         | More window UI controls          | Icon buttons, toolbars, hyperlinks, dropdown menu buttons, multi-select checklists, chip/tag groups, time pickers, and a live password strength meter.    | ![Snapshot 10](../snapshots/ex10.png)  |
| **[`11_data_table_pro.v`](11_data_table_pro.v)**                       | Data table pro                   | Sortable columns (click header, numeric-aware compare), mouse-wheel scrolling for fixed-height tables, row hover highlight, and row add/remove/sort APIs. | Run locally to preview                 |
| **[`12_system_and_stdlib_features.v`](12_system_and_stdlib_features.v)** | System calls & stdlib toolkit    | Desktop notifications, hardware specs (CPU/RAM/cores), clipboard read/write, system paths, HTTP GET, RegEx, SHA256 crypto, and random password generator. | ![Snapshot 12](../snapshots/ex12.png)  |
| **[`13_reactive_state_store.v`](13_reactive_state_store.v)**           | Reactive state & persistence     | Key-value state store, typed accessors (`int`/`bool`), reactive state listeners (`on_state_change`), and JSON disk serialization/restoration.             | ![Snapshot 13](../snapshots/ex13.png)  |

---

## 🚀 How to Run the Demos

```bash
# Run Quickstart Demo
v run examples/01_quickstart.v

# Run Theme Gallery Demo
v run examples/02_theme_gallery.v

# Run Layout Containers Demo
v run examples/03_layout_containers.v

# Run Component Gallery Demo
v run examples/04_widgets_and_forms.v

# Run Nameless Shortcuts Demo
v run examples/05_nameless_shortcuts.v

# Run Interactive Dashboard Demo
v run examples/06_dashboard_app.v

# Run Advanced Controls Demo
v run examples/07_advanced_controls.v

# Run RAD Application Builder Demo
v run examples/08_rad_development.v

# Run Control Customization & Geometry Demo
v run examples/09_control_customization.v

# Run More Window UI Controls Demo
v run examples/10_more_controls.v

# Run Data Table Pro Demo
v run examples/11_data_table_pro.v

# Run System & Stdlib Toolkit Demo
v run examples/12_system_and_stdlib_features.v

# Run Reactive State Store Demo
v run examples/13_reactive_state_store.v
```
