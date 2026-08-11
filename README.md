# `simple_gg` - Cross-Platform SimpleGUI for V

`simple_gg` is a lightweight, beginner-friendly UI framework for building native, hardware-accelerated desktop applications in V. Built on top of V's native `gg` graphics module (powered by Sokol), `simple_gg` delivers smooth performance and uniform UI rendering across **macOS, Linux, and Windows** without relying on external C/Obj-C dependencies.

---

## 🎨 Visual Showcase & Snapshots of All Examples

<p align="center">
  <img src="snapshots/ex1.png" width="48%" alt="Quickstart Demo" />
  <img src="snapshots/ex6.png" width="48%" alt="Dashboard App Demo" />
</p>
<p align="center">
  <img src="snapshots/ex7.png" width="48%" alt="Advanced Controls Demo" />
  <img src="snapshots/ex14.png" width="48%" alt="RAD Controls Showcase" />
</p>
<p align="center">
  <img src="snapshots/ex15.png" width="48%" alt="Modern UI Showcase" />
  <img src="snapshots/ex17.png" width="48%" alt="Data & Event Binding" />
</p>

<details>
<summary><b>📸 Click to view all 17 example screenshots</b></summary>
<br/>

<p align="center">
  <img src="snapshots/ex1.png" width="48%" alt="01 - Quickstart Demo" />
  <img src="snapshots/ex2.png" width="48%" alt="02 - Theme Gallery Demo" />
</p>
<p align="center">
  <img src="snapshots/ex3.png" width="48%" alt="03 - Layout Containers Demo" />
  <img src="snapshots/ex4.png" width="48%" alt="04 - Component Gallery Demo" />
</p>
<p align="center">
  <img src="snapshots/ex5.png" width="48%" alt="05 - Nameless Shortcuts Demo" />
  <img src="snapshots/ex6.png" width="48%" alt="06 - Interactive Dashboard Demo" />
</p>
<p align="center">
  <img src="snapshots/ex7.png" width="48%" alt="07 - Advanced Controls Demo" />
  <img src="snapshots/ex8.png" width="48%" alt="08 - RAD Application Builder Demo" />
</p>
<p align="center">
  <img src="snapshots/ex9.png" width="48%" alt="09 - Control Customization Demo" />
  <img src="snapshots/ex10.png" width="48%" alt="10 - More UI Controls Demo" />
</p>
<p align="center">
  <img src="snapshots/ex11.png" width="48%" alt="11 - Data Table Pro Demo" />
  <img src="snapshots/ex12.png" width="48%" alt="12 - System & Stdlib Toolkit Demo" />
</p>
<p align="center">
  <img src="snapshots/ex13.png" width="48%" alt="13 - Reactive State Store Demo" />
  <img src="snapshots/ex14.png" width="48%" alt="14 - RAD Controls Showcase Demo" />
</p>
<p align="center">
  <img src="snapshots/ex15.png" width="48%" alt="15 - Modern UI Features Showcase Demo" />
  <img src="snapshots/ex16.png" width="48%" alt="16 - Interval Timers Demo" />
</p>
<p align="center">
  <img src="snapshots/ex17.png" width="48%" alt="17 - Data & Event Binding Demo" />
</p>

</details>

---

## ✨ Key Features

- ⚡ **Cross-Platform**: Runs natively on macOS, Linux, and Windows with native OS drag-and-drop support.
- 🎨 **17 Built-in Production Themes**: Apple Light/Dark, Nord, Dracula, Cyberpunk, Catppuccin Mocha, GitHub Dark/Light, Solarized, etc.
- 🛠️ **RAD Development Controls Suite**: Multi-select Tag Input, Dual-Thumb Range Slider, Monospace Code Editor, File Drop Zone, Property Grid Inspector, Sparkline Micro-Charts, Pagination Bar, Resizable Split View, Toast Notification Overlay Stack, Command Palette (`Ctrl+K`), and Context Menus.
- 🧩 **Complete Widget Set**: ListBox (interactive single/multi select), ComboBox, Transfer List, Console Output Viewer, Color Palette Swatch Grid, Status Bar, Step Slider, text/password inputs, steppers, range sliders, toggle switches, checkboxes, dropdowns, segmented controls, rating stars, date pickers, metric cards, charts, tree views, data tables, breadcrumbs, avatars, status badges, accordions, and alert banners.
- 📐 **Layout Engine**: Automatic vertical stacking, horizontal rows (`begin_row`), multi-column grids (`begin_grid`), flexboxes (`begin_flex_box`), tab containers, and group cards.
- 🔄 **Reactive State Management (`state.v`)**: Key-value reactive store (`set_state`, `get_state`), typed accessors, reactive state listeners (`on_state_change`), and JSON disk persistence (`save_state_json`, `load_state_json`).
- 💻 **OS & System Extensions (`sys.v`)**: Native notifications, hardware/RAM/CPU inspection, system process execution, clipboard access, environment variables, system directories, and file operations.
- 🛠️ **V Standard Library Integrations (`stdlib.v`)**: Built-in fluent helpers for HTTP requests, RegEx matching, Cryptography (SHA256, MD5, AES, Bcrypt), Gzip/Zlib/Zstd compression, TOML parsing, SemVer checks, and WebSockets.
- 🚀 **Beginner Friendly**: Fluent chainable builder API with zero boilerplate.

---

## ⚡ Quick Start

```v
module main

import simplegui

fn main() {
	mut win := simplegui.new_simple_window('My App', 520, 380)
	win.set_theme('Apple Dark')
	win.add_heading('SimpleGUI Starter')
	win.add_form_field('Name:', 'username', 'Ada Lovelace')
	win.add_checkbox('agree', 'I agree to the Terms', true)

	win.add_button('btn_save', 'Save')
	win.on_click('btn_save', fn (mut win simplegui.SimpleWindow) {
		println("User: ${win.get_text('username')}")
	})

	win.run()
}
```

---

## 📁 Beginner-Friendly Examples & Snapshots

The repository includes beginner-friendly example programs in the [`examples/`](examples) directory:

| Example | Description | Run Command | Snapshot |
| :--- | :--- | :--- | :--- |
| **[`01_quickstart.v`](examples/01_quickstart.v)** | First starter app with inputs and button callbacks. | `v run examples/01_quickstart.v` | ![Snapshot 01](snapshots/ex1.png) |
| **[`02_theme_gallery.v`](examples/02_theme_gallery.v)** | Live theme switcher across 34 production palettes. | `v run examples/02_theme_gallery.v` | ![Snapshot 02](snapshots/ex2.png) |
| **[`03_layout_containers.v`](examples/03_layout_containers.v)** | Horizontal rows, multi-column grids, and group cards. | `v run examples/03_layout_containers.v` | ![Snapshot 03](snapshots/ex3.png) |
| **[`04_widgets_and_forms.v`](examples/04_widgets_and_forms.v)** | Form inputs, sliders, steppers, ratings, dates, and metric cards. | `v run examples/04_widgets_and_forms.v` | ![Snapshot 04](snapshots/ex4.png) |
| **[`05_nameless_shortcuts.v`](examples/05_nameless_shortcuts.v)** | Rapid prototyping using nameless shortcuts (`win.input()`). | `v run examples/05_nameless_shortcuts.v` | ![Snapshot 05](snapshots/ex5.png) |
| **[`06_dashboard_app.v`](examples/06_dashboard_app.v)** | Real-world dashboard with KPI metrics, charts, and actions. | `v run examples/06_dashboard_app.v` | ![Snapshot 06](snapshots/ex6.png) |
| **[`07_advanced_controls.v`](examples/07_advanced_controls.v)** | Data tables, tab containers, tree views, search, breadcrumbs, avatars, and shortcuts. | `v run examples/07_advanced_controls.v` | ![Snapshot 07](snapshots/ex7.png) |
| **[`08_rad_development.v`](examples/08_rad_development.v)** | Rapid app builder with batch ops, JSON form export, clipboard, and OS dialogs. | `v run examples/08_rad_development.v` | ![Snapshot 08](snapshots/ex8.png) |
| **[`09_control_customization.v`](examples/09_control_customization.v)** | Custom geometry, margins/padding, colors, borders, and fluent control chaining. | `v run examples/09_control_customization.v` | ![Snapshot 09](snapshots/ex9.png) |
| **[`10_more_controls.v`](examples/10_more_controls.v)** | Icon buttons, toolbars, hyperlinks, checklists, chips, and password strength meter. | `v run examples/10_more_controls.v` | ![Snapshot 10](snapshots/ex10.png) |
| **[`11_data_table_pro.v`](examples/11_data_table_pro.v)** | Sortable data tables, wheel scrolling, row hover, and table manipulation. | `v run examples/11_data_table_pro.v` | ![Snapshot 11](snapshots/ex11.png) |
| **[`12_system_and_stdlib_features.v`](examples/12_system_and_stdlib_features.v)** | Desktop notifications, hardware specs, clipboard, system paths, HTTP GET, RegEx, Crypto. | `v run examples/12_system_and_stdlib_features.v` | ![Snapshot 12](snapshots/ex12.png) |
| **[`13_reactive_state_store.v`](examples/13_reactive_state_store.v)** | Reactive key-value state store, typed accessors, state change listeners, and JSON disk persistence. | `v run examples/13_reactive_state_store.v` | ![Snapshot 13](snapshots/ex13.png) |
| **[`14_rad_controls_showcase.v`](examples/14_rad_controls_showcase.v)** | RAD & Advanced Suite: ListBox, Multi-Select ListBox, ComboBox, Transfer List, Code Editor, Console Log, Color Palette, Step Slider, Status Bar, Tag Input, Range Slider, Drop Zone, Property Grid, Sparkline, Pagination, Split View, Toasts, Command Palette, Context Menu. | `v run examples/14_rad_controls_showcase.v` | ![Snapshot 14](snapshots/ex14.png) |
| **[`15_modern_ui_features_showcase.v`](examples/15_modern_ui_features_showcase.v)** | Modern UI Showcase: Window controls, themes, layouts, forms, state store, system utilities. | `v run examples/15_modern_ui_features_showcase.v` | ![Snapshot 15](snapshots/ex15.png) |
| **[`16_interval_timers.v`](examples/16_interval_timers.v)** | Interval Timers & Timeouts: Recurring timers, timeouts, clock, auto progress bar. | `v run examples/16_interval_timers.v` | ![Snapshot 16](snapshots/ex16.png) |
| **[`17_data_and_event_binding.v`](examples/17_data_and_event_binding.v)** | Data & Event Binding: Two-way state binding (`bind_state`), click aliases, shortcut bindings. | `v run examples/17_data_and_event_binding.v` | ![Snapshot 17](snapshots/ex17.png) |

---

## 📘 Documentation

- **Full API Guide**: See [API.md](API.md) for complete details on window configuration, controls, layout engine, themes, event callbacks, reactive state management (`state.v`), system calls (`sys.v`), and standard library extensions (`stdlib.v`).
- **Examples Guide**: See [examples/README.md](examples/README.md) for detailed descriptions of all example scripts.
