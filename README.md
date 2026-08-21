# `simple_gg` - Cross-Platform SimpleGUI for V

`simple_gg` is a lightweight, beginner-friendly UI framework for building native, hardware-accelerated desktop applications in V. Built on top of V's native `gg` graphics module (powered by Sokol), `simple_gg` delivers smooth performance and uniform UI rendering across **macOS, Linux, and Windows** without relying on external C/Obj-C dependencies.

---

### 🎨 Visual Showcase & Snapshots of All Examples

<p align="center">
  <img src="snapshots/ex24.png" width="48%" alt="Custom 3D Image Dialogs Demo" />
  <img src="snapshots/ex23.png" width="48%" alt="Modern Image Controls Demo" />
</p>
<p align="center">
  <img src="snapshots/ex22.png" width="48%" alt="Super Controls Suite Demo" />
  <img src="snapshots/ex14.png" width="48%" alt="RAD Controls Showcase" />
</p>
<p align="center">
  <img src="snapshots/ex1.png" width="48%" alt="Quickstart Demo" />
  <img src="snapshots/ex6.png" width="48%" alt="Dashboard App Demo" />
</p>

<details>
<summary><b>📸 Click to view remaining example screenshots (18 more)</b></summary>
<br/>

<p align="center">
  <img src="snapshots/ex2.png" width="48%" alt="02 - Theme Gallery Demo" />
  <img src="snapshots/ex3.png" width="48%" alt="03 - Layout Containers Demo" />
</p>
<p align="center">
  <img src="snapshots/ex4.png" width="48%" alt="04 - Component Gallery Demo" />
  <img src="snapshots/ex5.png" width="48%" alt="05 - Nameless Shortcuts Demo" />
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
  <img src="snapshots/ex15.png" width="48%" alt="15 - Modern UI Features Showcase Demo" />
</p>
<p align="center">
  <img src="snapshots/ex16.png" width="48%" alt="16 - Interval Timers Demo" />
  <img src="snapshots/ex17.png" width="48%" alt="17 - Data & Event Binding Demo" />
</p>
<p align="center">
  <img src="snapshots/ex18.png" width="48%" alt="18 - Custom Font Typography Demo" />
  <img src="snapshots/ex19.png" width="48%" alt="19 - Cross-Window Spy Demo" />
</p>
<p align="center">
  <img src="snapshots/ex20.png" width="48%" alt="20 - Stdlib Data Structures Demo" />
  <img src="snapshots/ex21.png" width="48%" alt="21 - Extended OS System Calls Demo" />
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
| **[`01_quickstart.v`](examples/01_quickstart.v)** | First starter app with inputs and button callbacks. | `v run examples/01_quickstart.v` | [📸 Snapshot](snapshots/ex1.png) |
| **[`02_theme_gallery.v`](examples/02_theme_gallery.v)** | Live theme switcher across 34 production palettes. | `v run examples/02_theme_gallery.v` | [📸 Snapshot](snapshots/ex2.png) |
| **[`03_layout_containers.v`](examples/03_layout_containers.v)** | Horizontal rows, multi-column grids, and group cards. | `v run examples/03_layout_containers.v` | [📸 Snapshot](snapshots/ex3.png) |
| **[`04_widgets_and_forms.v`](examples/04_widgets_and_forms.v)** | Form inputs, sliders, steppers, ratings, dates, and metric cards. | `v run examples/04_widgets_and_forms.v` | [📸 Snapshot](snapshots/ex4.png) |
| **[`05_nameless_shortcuts.v`](examples/05_nameless_shortcuts.v)** | Rapid prototyping using nameless shortcuts (`win.input()`). | `v run examples/05_nameless_shortcuts.v` | [📸 Snapshot](snapshots/ex5.png) |
| **[`06_dashboard_app.v`](examples/06_dashboard_app.v)** | Real-world dashboard with KPI metrics, charts, and actions. | `v run examples/06_dashboard_app.v` | [📸 Snapshot](snapshots/ex6.png) |
| **[`07_advanced_controls.v`](examples/07_advanced_controls.v)** | Data tables, tab containers, tree views, search, breadcrumbs, avatars, and shortcuts. | `v run examples/07_advanced_controls.v` | [📸 Snapshot](snapshots/ex7.png) |
| **[`08_rad_development.v`](examples/08_rad_development.v)** | Rapid app builder with batch ops, JSON form export, clipboard, and OS dialogs. | `v run examples/08_rad_development.v` | [📸 Snapshot](snapshots/ex8.png) |
| **[`09_control_customization.v`](examples/09_control_customization.v)** | Custom geometry, margins/padding, colors, borders, and fluent control chaining. | `v run examples/09_control_customization.v` | [📸 Snapshot](snapshots/ex9.png) |
| **[`10_more_controls.v`](examples/10_more_controls.v)** | Icon buttons, toolbars, hyperlinks, checklists, chips, and password strength meter. | `v run examples/10_more_controls.v` | [📸 Snapshot](snapshots/ex10.png) |
| **[`11_data_table_pro.v`](examples/11_data_table_pro.v)** | Sortable data tables, wheel scrolling, row hover, and table manipulation. | `v run examples/11_data_table_pro.v` | [📸 Snapshot](snapshots/ex11.png) |
| **[`12_system_and_stdlib_features.v`](examples/12_system_and_stdlib_features.v)** | Desktop notifications, hardware specs, clipboard, system paths, HTTP GET, RegEx, Crypto. | `v run examples/12_system_and_stdlib_features.v` | [📸 Snapshot](snapshots/ex12.png) |
| **[`13_reactive_state_store.v`](examples/13_reactive_state_store.v)** | Reactive key-value state store, typed accessors, state change listeners, and JSON disk persistence. | `v run examples/13_reactive_state_store.v` | [📸 Snapshot](snapshots/ex13.png) |
| **[`14_rad_controls_showcase.v`](examples/14_rad_controls_showcase.v)** | RAD & Advanced Suite: ListBox, Multi-Select ListBox, ComboBox, Transfer List, Code Editor, Console Log, Color Palette, Step Slider, Status Bar, Tag Input, Range Slider, Drop Zone, Property Grid, Sparkline, Pagination, Split View, Toasts, Command Palette, Context Menu. | `v run examples/14_rad_controls_showcase.v` | [📸 Snapshot](snapshots/ex14.png) |
| **[`15_modern_ui_features_showcase.v`](examples/15_modern_ui_features_showcase.v)** | Modern UI Showcase: Window controls, themes, layouts, forms, state store, system utilities. | `v run examples/15_modern_ui_features_showcase.v` | [📸 Snapshot](snapshots/ex15.png) |
| **[`16_interval_timers.v`](examples/16_interval_timers.v)** | Interval Timers & Timeouts: Recurring timers, timeouts, clock, auto progress bar. | `v run examples/16_interval_timers.v` | [📸 Snapshot](snapshots/ex16.png) |
| **[`17_data_and_event_binding.v`](examples/17_data_and_event_binding.v)** | Data & Event Binding: Two-way state binding (`bind_state`), click aliases, shortcut bindings. | `v run examples/17_data_and_event_binding.v` | [📸 Snapshot](snapshots/ex17.png) |
| **[`18_custom_font_loading.v`](examples/18_custom_font_loading.v)** | Custom Font & Typography: Platform font resolution, custom TTF/OTF setting, font discovery. | `v run examples/18_custom_font_loading.v` | [📸 Snapshot](snapshots/ex18.png) |
| **[`19_cross_window_spy_and_automation.v`](examples/19_cross_window_spy_and_automation.v)** | Cross-Window Spy++ & Automation: Global window registry, control inspection, event bus. | `v run examples/19_cross_window_spy_and_automation.v` | [📸 Snapshot](snapshots/ex19.png) |
| **[`20_stdlib_data_structures_math_and_sockets.v`](examples/20_stdlib_data_structures_math_and_sockets.v)** | Collections, Math & Sockets: Stack, Queue, Set, MinHeap, BigInt, string distance metrics. | `v run examples/20_stdlib_data_structures_math_and_sockets.v` | [📸 Snapshot](snapshots/ex20.png) |
| **[`21_extended_os_system_calls.v`](examples/21_extended_os_system_calls.v)** | Extended OS & Hardware: CPU/memory pressure, environment variables, audio beeps, zip. | `v run examples/21_extended_os_system_calls.v` | [📸 Snapshot](snapshots/ex21.png) |
| **[`22_modern_super_controls_showcase.v`](examples/22_modern_super_controls_showcase.v)** | Super Controls Suite: Super Terminal, Code Studio, Smart Table, Kanban Board, Wizard Stepper, Floating Toolbar, Score Card, Sparklines, Donut Chart, Chip Input. | `v run examples/22_modern_super_controls_showcase.v` | [📸 Snapshot](snapshots/ex22.png) |
| **[`23_modern_image_controls_showcase.v`](examples/23_modern_image_controls_showcase.v)** | Modern Image Controls: User Profile Cards, Product Cards, Multi-Image Showcase Gallery, 3D App Launcher Tiles, Media Player Card, Hero Banners, and Hardware Texture Caching. | `v run examples/23_modern_image_controls_showcase.v` | [📸 Snapshot](snapshots/ex23.png) |
| **[`24_custom_image_dialogs_showcase.v`](examples/24_custom_image_dialogs_showcase.v)** | RAD Custom 3D Image Dialogs: 3D glossy icons (Success, Error, Warning, Info, Confirm, Danger, Security, Database, Cloud, Tip), 3-button actions, Checkboxes & Inline Input Prompts. | `v run examples/24_custom_image_dialogs_showcase.v` | [📸 Snapshot](snapshots/ex24.png) |


---

## 📘 Documentation

- **Full API Guide**: See [API.md](API.md) for complete details on window configuration, controls, layout engine, themes, event callbacks, reactive state management (`state.v`), system calls (`sys.v`), and standard library extensions (`stdlib.v`).
- **Examples Guide**: See [examples/README.md](examples/README.md) for detailed descriptions of all example scripts.
