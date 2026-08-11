# `simple_gg` - Cross-Platform SimpleGUI for V

`simple_gg` is a lightweight, beginner-friendly UI framework for building native, hardware-accelerated desktop applications in V. Built on top of V's native `gg` graphics module (powered by Sokol), `simple_gg` delivers smooth performance and uniform UI rendering across **macOS, Linux, and Windows** without relying on external C/Obj-C dependencies.

---

## 🎨 Visual Showcase & Snapshots of All Examples

````carousel
![01 - Quickstart Demo](snapshots/ex1.png)
<!-- slide -->
![02 - Theme Gallery Demo](snapshots/ex2.png)
<!-- slide -->
![03 - Layout Containers Demo](snapshots/ex3.png)
<!-- slide -->
![04 - Component Gallery Demo](snapshots/ex4.png)
<!-- slide -->
![05 - Nameless Shortcuts Demo](snapshots/ex5.png)
<!-- slide -->
![06 - Interactive Dashboard Demo](snapshots/ex6.png)
````

---

## ✨ Key Features

- ⚡ **Cross-Platform**: Runs natively on macOS, Linux, and Windows.
- 🎨 **17 Built-in Production Themes**: Apple Light/Dark, Nord, Dracula, Cyberpunk, Catppuccin Mocha, GitHub Dark/Light, Solarized, etc.
- 🧩 **Complete Widget Set**: Text/password inputs, steppers, range sliders, toggle switches, checkboxes, dropdowns, segmented controls, rating stars, date pickers, metric cards, charts, list boxes, and alert banners.
- 📐 **Layout Engine**: Automatic vertical stacking, horizontal rows (`begin_row`), multi-column grids (`begin_grid`), flexboxes (`begin_flex_box`), and group cards.
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

The repository includes 6 beginner-friendly example programs in the [`examples/`](examples) directory:

| Example | Description | Run Command | Snapshot |
| :--- | :--- | :--- | :--- |
| **[`01_quickstart.v`](examples/01_quickstart.v)** | First starter app with inputs and button callbacks. | `v run examples/01_quickstart.v` | ![Snapshot 01](snapshots/ex1.png) |
| **[`02_theme_gallery.v`](examples/02_theme_gallery.v)** | Live theme switcher across 17 production palettes. | `v run examples/02_theme_gallery.v` | ![Snapshot 02](snapshots/ex2.png) |
| **[`03_layout_containers.v`](examples/03_layout_containers.v)** | Horizontal rows, multi-column grids, and group cards. | `v run examples/03_layout_containers.v` | ![Snapshot 03](snapshots/ex3.png) |
| **[`04_widgets_and_forms.v`](examples/04_widgets_and_forms.v)** | Form inputs, sliders, steppers, ratings, dates, and metric cards. | `v run examples/04_widgets_and_forms.v` | ![Snapshot 04](snapshots/ex4.png) |
| **[`05_nameless_shortcuts.v`](examples/05_nameless_shortcuts.v)** | Rapid prototyping using nameless shortcuts (`win.input()`). | `v run examples/05_nameless_shortcuts.v` | ![Snapshot 05](snapshots/ex5.png) |
| **[`06_dashboard_app.v`](examples/06_dashboard_app.v)** | Real-world dashboard with KPI metrics, charts, and actions. | `v run examples/06_dashboard_app.v` | ![Snapshot 06](snapshots/ex6.png) |

---

## 📘 Documentation

- **Full API Guide**: See [API.md](API.md) for complete details on window configuration, controls, layout engine, themes, and event callbacks.
- **Examples Guide**: See [examples/README.md](examples/README.md) for detailed descriptions of all example scripts.
