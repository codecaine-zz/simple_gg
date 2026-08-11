# SimpleGUI (`simple_gg`) - Complete API Reference & Beginner Guide

`simplegui` (in package `simple_gg`) is a lightweight, zero-dependency, Rapid Application Development (RAD) UI toolkit for building desktop applications in V using V's native `gg` graphics engine.

Whether you are building a 5-minute utility tool, a multi-tab admin panel, or an interactive data app, `simplegui` lets you create sleek interfaces with concise code, rich built-in themes, reactive state management, and OS system calls.

> [!NOTE]
> Standard sokol/gg text rendering uses standard font glyphs. Avoid emoji characters in UI text labels to ensure clean cross-platform font rendering. Use standard ASCII characters or brackets like `[+]`, `[-]`, `[Save]`, `[Home]`, `[Settings]` for icons and indicators.

---

## Quick Navigation Index

1. [60-Second Copy-Paste Starter App](#1-60-second-copy-paste-starter-app)
2. [Window Setup, Sizing & Content Fitting](#2-window-setup-sizing--content-fitting)
3. [Built-in Themes & Styling](#3-built-in-themes--styling)
4. [Layout Containers & Grouping](#4-layout-containers--grouping)
5. [Widget Reference (Complete Catalog)](#5-widget-reference-complete-catalog)
6. [Form RAD Helpers (Label + Widget Pairs)](#6-form-rad-helpers-label--widget-pairs)
7. [Nameless RAD Shortcuts](#7-nameless-rad-shortcuts)
8. [Widget Styling & Fluent Method Chaining](#8-widget-styling--fluent-method-chaining)
9. [Reading & Writing Control Values](#9-reading--writing-control-values)
10. [Event Listeners & Callbacks](#10-event-listeners--callbacks)
11. [RAD Utilities & Form JSON Serialization](#11-rad-utilities--form-json-serialization)
12. [Reactive State Store & JSON Persistence](#12-reactive-state-store--json-persistence)
13. [OS System Calls & Hardware API](#13-os-system-calls--hardware-api)
14. [V Standard Library Integrations](#14-v-standard-library-integrations)
15. [Ergonomic Standalone Functions](#15-ergonomic-standalone-functions)
16. [Interval Timers & Scheduled Callbacks](#16-interval-timers--scheduled-callbacks)
17. [Modern UI & RAD UX Enhancements](#17-modern-ui--rad-ux-enhancements)
18. [Data & Event Binding (`bind`)](#18-data--event-binding-bind)

---

## 1. 60-Second Copy-Paste Starter App

Copy this complete example into a `main.v` file and run `v run .` to launch your first desktop app:

```v
module main

import simplegui

fn main() {
	// 1. Create a modern window (Width: 640px, Height: 480px)
	mut win := simplegui.new_simple_window('Quick Profile Editor', 640, 480)
	
	// 2. Pick a stylish dark theme (Nord, Apple Dark, Dracula, Cyberpunk, etc.)
	win.set_theme('Apple Dark')

	// 3. Add UI Headings & Labeled Form Fields
	win.add_heading('User Profile Settings')
	win.add_form_field('Full Name:', 'input_name', 'Ada Lovelace')
	win.add_form_field('Email Address:', 'input_email', 'ada@vlang.io')
	win.add_checkbox('chk_newsletter', 'Subscribe to Monthly Tech Digest', true)

	// 4. Add Buttons inside a Horizontal Row
	win.begin_row('action_row')
	win.add_button('btn_save', '[Save] Save Profile')
	win.add_button('btn_reset', '[R] Reset Fields')
	win.end_row()

	// 5. Add Interactive Event Handlers
	win.on_click('btn_save', fn (mut win simplegui.SimpleWindow) {
		name := win.get_text('input_name')
		email := win.get_text('input_email')
		subscribed := win.get_bool('chk_newsletter')

		// Show a floating toast notification alert
		win.info('Profile Saved!', 'Updated ${name} (${email}) - Digest: ${subscribed}')
	})

	win.on_click('btn_reset', fn (mut win simplegui.SimpleWindow) {
		win.set_text('input_name', '')
		win.set_text('input_email', '')
		win.set_bool('chk_newsletter', false)
		win.warn('Fields Reset', 'All input fields cleared.')
	})

	// 6. Launch the Window Event Loop
	win.run()
}
```

---

## 2. Window Setup, Sizing & Content Fitting

### Create Window

```v
// Create a standard window with Title, Width, and Height
mut win := simplegui.new_simple_window('My Desktop App', 800, 600)

// Alias syntax (identical functionality)
mut win2 := simplegui.new_window('My Desktop App', 800, 600)
```

### Window Dimensions & Width Sizing

You can adjust window width and height programmatically. Layout calculations update automatically when dimensions change.

```v
// Set window width specifically
win.set_width(900)

// Set window height specifically
win.set_height(650)

// Set both width and height
win.set_size(1024, 768)

// Alias for set_size
win.resize(1024, 768)

// Read window dimensions
w := win.get_width()
h := win.get_height()
w, h = win.get_size()
```

### Automatic Window Content Fitting (`fit_to_content`)

If your window controls exceed the initial width or height, call `fit_to_content()` to automatically recalculate and expand the window width and height so everything fits without clipping:

```v
mut win := simplegui.new_simple_window('Data Table App', 400, 300)

// Add wide data table or large controls
win.add_table('tbl_wide', ['ID', 'User Name', 'Email Address', 'Department', 'Access Role'], [
	['101', 'Ada Lovelace', 'ada@vlang.io', 'Engineering', 'System Architect'],
	['102', 'Alan Turing', 'alan@vlang.io', 'Research & AI', 'Lead Scientist'],
])

// Automatically expands window width and height to fit all visible controls + padding
win.fit_to_content()
// Or alias: win.fit_contents()

win.run()
```

### Size Presets & Window Locking

```v
// Lock window to fixed dimensions (prevents manual resizing)
win.set_fixed_size(500, 400)

// Minimum and maximum size constraints
win.set_min_size(400, 300)
win.set_max_size(1920, 1080)

// Preset sizes: 'small' (400x300), 'medium' (640x480), 'large' (800x600),
// 'hd' (1280x720), 'full_hd' (1920x1080), 'dialog' (420x220), 'settings' (600x500)
win.set_size_preset('hd')
```

### Full Screen Control

```v
win.set_fullscreen(true)     // Enable full screen window
win.toggle_fullscreen()      // Toggle full screen state
is_fs := win.is_fullscreen() // Returns true if currently full screen
```

### RAD Preset Window Types

```v
// Create a centered non-resizable dialog window
mut dialog := simplegui.new_simple_window('Dialog', 420, 220).make_fixed_dialog('Confirm Action', 420, 220)

// Create a borderless splash screen window
mut splash := simplegui.new_simple_window('Splash', 500, 300).make_splash_screen(500, 300)

// Create a slim floating utility panel
mut panel := simplegui.new_simple_window('Panel', 300, 600).make_utility_panel()
```

### Positioning, Alignment & Window Animations

```v
// Center window on screen
win.center_window()

// Align window on screen: 'top_left', 'top_right', 'bottom_left', 'bottom_right', 'center'
win.align_window('top_right')

// Shake window animation (e.g. invalid login entry feedback)
win.shake_window()

// Set opacity (0.0 to 1.0)
win.set_opacity(0.95)

// Make window movable by clicking anywhere on background
win.set_movable_by_window_background(true)

// Keep window stayed on top of other desktop windows
win.set_always_on_top(true)
```

### Window Lifecycle

```v
// Start window loop (blocks thread until window closes)
win.run()

// Programmatically close or hide window
win.close_window()
win.hide_window()
win.restore_window()
```

---

## 3. Built-in Themes & Styling

`simplegui` includes 34 curated light and dark themes across macOS, Futuristic/Sci-Fi, Business/Corporate, and Developer categories with interactive hover palettes (`hover_color` and `surface_hover`). Setting a theme instantly updates all controls, fonts, hover states, cards, and background colors.

```v
// Apply theme by name
win.set_theme('Synthwave 84')

// Toggle between Apple Light and Apple Dark themes
win.toggle_window_theme()

// List all available theme names (34 built-in themes)
themes := simplegui.list_themes()

// Get Theme struct by alias
theme := simplegui.get_theme('executive') // Accepts 'dark', 'nord', 'synthwave', 'corporate', 'matrix', etc.
// Theme fields include: theme.background_color, theme.font_color, theme.accent_color, theme.hover_color, theme.surface_hover
```

### Themes Reference Table

| Theme Name | Style Description | Background | Accent Color | Hover Color | Type |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`Apple Light`** | Default clean macOS light mode | `#ffffff` | `#007aff` | `#3395ff` | Light |
| **`Apple Dark`** | Modern macOS dark mode | `#1c1c1e` | `#0a84ff` | `#409cff` | Dark |
| **`Synthwave 84`** | Retro 80s synthwave neon twilight | `#261535` | `#ff7edb` | `#36f9f6` | Dark |
| **`Neon Matrix`** | Digital phosphor green cyber terminal | `#05100a` | `#39ff14` | `#00ffaa` | Dark |
| **`Holodeck Cyan`** | Futuristic glowing holographic cyan | `#050b14` | `#00f0ff` | `#70f3ff` | Dark |
| **`Sci-Fi HUD Orange`** | Tactical amber cockpit HUD | `#121316` | `#ff6600` | `#ffcc00` | Dark |
| **`Quantum Violet`** | Quantum glow electric purple dark | `#110926` | `#9d4edd` | `#c77dff` | Dark |
| **`Corporate Navy`** | Enterprise corporate navy light mode | `#f8fafc` | `#1e40af` | `#2563eb` | Light |
| **`Executive Slate`** | Dark executive slate dashboard | `#1e293b` | `#3b82f6` | `#60a5fa` | Dark |
| **`Financial Gold`** | Fintech luxury gold & dark bronze | `#181614` | `#d97706` | `#f59e0b` | Dark |
| **`Enterprise Light`** | Clean modern SaaS admin panel | `#f3f4f6` | `#0d9488` | `#14b8a6` | Light |
| **`Modern Minimalist`** | Stark high-contrast monochrome | `#ffffff` | `#18181b` | `#3f3f46` | Light |
| **`Pro Charcoal`** | Sleek pro charcoal SaaS dark mode | `#18181b` | `#6366f1` | `#818cf8` | Dark |
| **`Tokyo Night`** | Iconic Tokyo neon night IDE theme | `#1a1b26` | `#7aa2f7` | `#bb9af7` | Dark |
| **`One Dark Pro`** | Atom One Dark editor palette | `#282c34` | `#61afef` | `#c678dd` | Dark |
| **`Gruvbox Dark`** | Retro warm orange/green developer theme | `#282828` | `#fabd2f` | `#fe8019` | Dark |
| **`Monokai Pro`** | Classic Monokai vivid dark palette | `#2d2a2e` | `#ff6188` | `#ffd866` | Dark |
| **`Rosé Pine`** | Natural rose gold & purple theme | `#191724` | `#ebbcba` | `#c4a7e7` | Dark |
| **`Coffee Roast`** | Warm cozy espresso dark mode | `#1c1613` | `#d97706` | `#f59e0b` | Dark |
| **`Nord`** | Cool arctic frost blue palette | `#2e3440` | `#88c0d0` | `#81a1c1` | Dark |
| **`Dracula`** | Classic vampire dark purple | `#282a36` | `#bd93f9` | `#ff79c6` | Dark |
| **`Cyberpunk`** | High-contrast neon dark vibe | `#0d0d15` | `#ff007f` | `#7000ff` | Dark |
| **`Catppuccin Mocha`** | Smooth pastel dark theme | `#1e1e2e` | `#cba6f7` | `#f5c2e7` | Dark |
| **`GitHub Dark`** | Official GitHub dark mode | `#0d1117` | `#58a6ff` | `#79c0ff` | Dark |
| **`GitHub Light`** | Official GitHub light mode | `#ffffff` | `#0969da` | `#218bff` | Light |
| **`Sonoma Emerald`** | Dark forest glass layout | `#0d1f18` | `#30d158` | `#4ade80` | Dark |
| **`Ventura Amber`** | Warm sunset dark palette | `#211815` | `#ff9500` | `#ffaa33` | Dark |

---

## 4. Layout Containers & Grouping

Organize controls easily using rows, grids, flexboxes, tabbed panels, split views, and group cards.

### 1. Horizontal Row (`begin_row` / `end_row`)

Arranges controls horizontally side-by-side:

```v
win.begin_row('btn_row')
win.add_button('btn_ok', 'OK')
win.add_button('btn_cancel', 'Cancel')
win.add_button('btn_help', 'Help')
win.end_row()
```

### 2. Grid Layout (`begin_grid` / `end_grid`)

Arranges controls into equal columns:

```v
// 3 columns with 12px gap
win.begin_grid('gallery_grid', 3, 12)
win.add_button('g1', 'Card 1')
win.add_button('g2', 'Card 2')
win.add_button('g3', 'Card 3')
win.add_button('g4', 'Card 4')
win.end_grid()
```

### 3. Flexbox Layout (`begin_flex_box` / `end_flex_box`)

Auto-calculates item widths to fill row space:

```v
win.begin_flex_box('flex_container')
win.add_button('f1', 'Flex Item 1')
win.add_button('f2', 'Flex Item 2')
win.end_flex_box()
```

### 4. Tabbed Container (`begin_tab_container` / `end_tab_container`)

Organizes complex interfaces into tabbed views:

```v
// Create container with 3 tabs: General (0), Security (1), About (2)
win.begin_tab_container('main_tabs', ['General', 'Security', 'About'])

// Tab Page 0: General
win.begin_tab_page('tab_gen', 0)
win.add_heading('General App Settings')
win.add_form_field('App Name:', 'input_app_name', 'My Dashboard')
win.end_tab_page()

// Tab Page 1: Security
win.begin_tab_page('tab_sec', 1)
win.add_heading('Security & Encryption')
win.add_checkbox('chk_2fa', 'Enable Two-Factor Authentication', true)
win.end_tab_page()

// Tab Page 2: About
win.begin_tab_page('tab_about', 2)
win.add_label('lbl_info', 'SimpleGUI Framework v1.0.0')
win.end_tab_page()

win.end_tab_container()
```

### 5. Split Pane View (`begin_split_view` / `end_split_view`)

Splits container into left sidebar and right main content area:

```v
// Left sidebar takes 30% width, right content takes 70%
win.begin_split_view('sidebar_split', 30)

// Left Region (Sidebar)
win.add_heading('Navigation')
win.add_button('nav_home', '[Home] Home')
win.add_button('nav_settings', '[Set] Settings')

// Right Region (Main Area)
win.add_heading('Main Dashboard Content')
win.add_label('lbl_dash', 'Select an option from the left sidebar.')

win.end_split_view()
```

### 6. Group Box Card (`group` / `begin_group`)

Wraps widgets in a visual card container with a header title:

```v
win.group('grp_account', 'User Credentials', fn (mut win simplegui.SimpleWindow) {
	win.add_form_field('Username:', 'input_u', 'admin')
	win.add_form_password('Password:', 'input_p', 'secret123')
})
```

### 7. Spacers & Separators

```v
win.add_spacer(20)     // Add 20px vertical blank space
win.add_separator()    // Horizontal rule line
```

---

## 5. Widget Reference (Complete Catalog)

Every widget is created with a unique `name` string identifier.

### Text Labels & Typography

```v
win.add_heading('Main Page Title')
win.add_subheading('Section Header')
win.add_label('lbl_status', 'Status: System Ready')
win.add_caption('Caption text description...')
win.add_divider('Optional Settings')
```

### Buttons

```v
win.add_button('btn_run', '[Run] Start Processing')

win.on_click('btn_run', fn (mut win simplegui.SimpleWindow) {
	win.info('Started', 'Processing job launched!')
})
```

### Inputs, Passwords & Textareas

```v
win.add_input('input_host', 'localhost')
win.add_password('input_secret', 'my_pass_123')
win.add_textarea('input_logs', 'Line 1: Started\nLine 2: Ready')
```

### Search Bar

```v
win.add_search_bar('search_box', 'Type to search records...')

win.on_enter('search_box', fn (mut win simplegui.SimpleWindow) {
	query := win.get_text('search_box')
	println('Search query submitted: ${query}')
})
```

### Checkboxes, Switches & Toggles

```v
win.add_checkbox('chk_debug', 'Enable Verbose Logging', false)
win.add_switch('sw_dark', 'Dark Theme Mode', true)
win.add_toggle('tgl_auto', 'Auto Save', true)
```

### Steppers & Sliders

```v
win.add_number('num_count', 5)        // Up/Down integer stepper
win.add_slider('slider_vol', 75)      // Range slider 0 to 100
win.add_progress_bar('prog_bar', 65)  // Progress bar indicator
```

### Dropdowns & Segmented Controls

```v
win.add_dropdown('drop_role', ['Administrator', 'Developer', 'Guest'], 'Developer')
win.add_segmented_control('seg_view', ['Grid View', 'List View', 'Map'], 'Grid View')
```

### Data Table

Supports header sorting, row selection, scrolling, and dynamic dataset updating:

```v
headers := ['ID', 'Full Name', 'Role', 'Status']
rows := [
	['1', 'Ada Lovelace', 'Mathematician', 'Active'],
	['2', 'Alan Turing', 'Cryptanalyst', 'Active'],
	['3', 'Grace Hopper', 'Computer Scientist', 'Offline'],
]

win.add_table('tbl_users', headers, rows)
win.set_control_height('tbl_users', 200)

// Programmatic sorting (Column 1 ascending)
win.sort_table('tbl_users', 1, true)

// Row selection event
win.on_row_click('tbl_users', fn (mut win simplegui.SimpleWindow) {
	idx := win.get_table_selected_row('tbl_users')
	println('Selected row index: ${idx}')
})

// Update dataset dynamically
win.set_table_data('tbl_users', headers, new_rows)
```

### Charts & KPI Cards

```v
// Line Chart
win.add_line_chart('chart_sales', 'Monthly Revenue ($k)', [12.5, 18.2, 24.0, 31.8, 42.0])

// Bar Chart
win.add_bar_chart('chart_visitors', 'Daily Visitors', ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'], [120.0, 240.0, 180.0, 310.0, 450.0])

// Metric KPI Card
win.add_metric_card('kpi_sales', 'Total Revenue', '$48,250', '+14.2%', 'vs last month')
```

### Lists, ListBox & Multi-Select

```v
// Single-Select ListBox
win.add_list_box_with_selected('list_files', ['file1.txt', 'file2.csv', 'document.pdf'], 'file1.txt')
selected_file := win.get_list_box_selected('list_files')
selected_idx := win.get_list_box_index('list_files')
win.set_list_box_selected('list_files', 'file2.csv')

// Multi-Select ListBox
win.add_multi_list_box('list_tags', ['macOS', 'Linux', 'Windows', 'WebAssembly'], ['macOS', 'Linux'])
selected_tags := win.get_multi_list_box_selected('list_tags')
win.set_multi_list_box_selected('list_tags', ['macOS', 'Windows'])

// Tree View
win.add_tree_view('tree_proj', [
	simplegui.TreeNode{
		title: 'src'
		children: [
			simplegui.TreeNode{ title: 'main.v' },
			simplegui.TreeNode{ title: 'utils.v' }
		]
	}
])
```

### Navigation & Badges

```v
win.add_breadcrumbs('nav_path', ['Home', 'Projects', 'SimpleGUI', 'Settings'])
win.add_badge('badge_status', 'ONLINE', 'success')
win.add_status_badge('badge_sys', 'Operational', 'active')
win.add_avatar('user_avatar', 'AL', 'Ada Lovelace')
win.add_stepper('step_wizard', ['Account Details', 'Billing', 'Review'], 1)
```

### Accordions & Alert Banners

```v
win.add_accordion('acc_faq', 'Frequently Asked Questions', 'SimpleGUI runs natively on macOS, Windows, and Linux.', false)
win.add_alert_banner('banner_info', 'Notice', 'System maintenance scheduled for tonight at midnight.', 'info')
```

### Pickers & Wells

```v
win.add_date_picker('input_date', '2026-08-11')
win.add_time_picker('input_time', '14:30')
win.add_file_picker('input_file', 'Choose File:', '/tmp/document.pdf')
win.add_color_picker('picker_color', 'Select Accent Color:', '#0a84ff')
win.add_color_well('swatch_accent', '#0a84ff')
```

### Media, Canvas & Links

```v
win.add_image_view('img_preview', 'Preview Image', 300, 200)
win.add_canvas('canvas_draw', 400, 200)
win.add_spinner('loading_spinner', 'Syncing data...')
win.add_link('link_docs', 'Open Official V Language Documentation', 'https://vlang.io')
```

### Tags & Utility Controls

```v
win.add_tag_cloud('tags_cloud', ['Vlang', 'GUI', 'Desktop', 'CrossPlatform'])
win.add_chip_group('chips_tags', ['Bug', 'Feature', 'Documentation'], ['Bug'])
win.add_rich_text('rich_desc', '**Bold** and *italic* text formatting supported.')
win.add_keyboard_shortcut('hk_save', 'Ctrl+S', 'Save Project')
win.add_toolbar('main_tb', [
	simplegui.ToolbarItem{ icon: '[New]', tooltip: 'New File', on_click: fn (mut win simplegui.SimpleWindow) {} },
	simplegui.ToolbarItem{ icon: '[Save]', tooltip: 'Save File', on_click: fn (mut win simplegui.SimpleWindow) {} }
])
win.add_menu_button('menu_actions', 'Actions v', ['Export PDF', 'Export CSV', 'Print'])
win.add_checklist('chk_perms', ['Read', 'Write', 'Execute'], ['Read'])
win.add_password_strength('pwd_meter', 'input_password')
```

### RAD Development Controls & Overlays

```v
// 🏷️ Multi-Select Tag Input (interactive chips with inline text entry and 'x' removal)
win.add_tag_input('my_tags', ['vlang', 'gui', 'rad'])
tags := win.get_tags('my_tags')
win.set_tags('my_tags', ['tag1', 'tag2'])

// 🎚️ Dual-Thumb Range Slider (min, max, cur_min, cur_max)
win.add_range_slider('my_range', 0.0, 100.0, 20.0, 80.0)
bounds := win.get_range_values('my_range') // returns [min_val, max_val]
win.set_range_values('my_range', 15.0, 85.0)

// 📝 Monospace Code Editor (line numbers sidebar & V syntax keyword highlighting)
win.add_code_editor('my_code', 'fn main() {\n    println("Hello V")\n}', 'v')

// 📁 File Drop Zone (accepts native OS drag-and-drop files across window or click-to-browse)
win.add_drop_zone('my_drop', 'Drag & drop files here or click to browse')

// Retrieve array of all dropped file paths ([]string)
files := win.get_dropped_files('my_drop') // or win.get_files('my_drop')
for file_path in files {
    println('Dropped file: ${file_path}')
}

// Clear dropped file list
win.clear_dropped_files('my_drop')

// 🛠️ Property Grid Inspector (Key-Value inspector table with inline typed controls)
win.add_property_grid('my_inspector', [
	simplegui.PropertyGridItem{ name: 'App Theme', val: 'Dark Mode', kind: 'text' },
	simplegui.PropertyGridItem{ name: 'Debug Mode', val: 'true', kind: 'bool' },
	simplegui.PropertyGridItem{ name: 'Accent Color', val: '#3b82f6', kind: 'color' },
])

// 📊 Sparkline Micro-Chart (high-density inline trend curves)
win.add_sparkline('my_sparkline', [15.0, 32.0, 28.0, 65.0, 48.0, 92.0, 75.0, 88.0])

// 🔢 Pagination Bar (< Prev | Page X of Y | Next >)
win.add_pagination('my_pagination', 1, 10)

// ↔️ Resizable Split View Container (pane divider with draggable handle)
win.add_split_view('my_split', 0.5) // ratio 0.1 to 0.9

// 🔔 Ephemeral Toast Stack (auto-dismissing notification alerts with click-to-close)
win.push_toast('Success', 'File exported successfully!', 'success', 3000) // variants: info, success, warning, error

// 🔍 Command Palette Modal (Ctrl+K / Cmd+K quick search modal)
win.show_command_palette([
	simplegui.CommandItem{
		id: 'cmd_save'
		title: 'Save Project State'
		category: 'File'
		shortcut: 'Ctrl+S'
		on_execute: fn (mut win simplegui.SimpleWindow) { win.push_toast('Saved', 'Project saved', 'info', 2000) }
	}
])
win.hide_command_palette()

// 🎯 Auto-Complete ComboBox (editable input paired with quick option dropdown)
win.add_combobox('my_combo', ['Option A', 'Option B', 'Option C'], 'Option A')
combo_val := win.get_combobox_selected('my_combo')
win.set_combobox_selected('my_combo', 'Option B')

// 🔄 Dual Transfer List (side-by-side list transfer box with Move Right/Left buttons)
win.add_transfer_list('my_transfer', ['Item 1', 'Item 2', 'Item 3'], ['Item 4'])
avail := win.get_transfer_list_available('my_transfer')
chosen := win.get_transfer_list_selected('my_transfer')

// 🎨 Color Palette Swatch Grid (swatch selection grid)
win.add_color_palette('my_pal', ['#3b82f6', '#10b981', '#ef4444', '#f59e0b', '#8b5cf6'], '#3b82f6')
color := win.get_color_selected('my_pal')
win.set_color_selected('my_pal', '#10b981')

// 📏 Discrete Step Slider (snaps to discrete tick marks)
win.add_step_slider('my_step_slider', 4, 50.0) // 4 steps, initial value 50%
step_val := win.get_step_slider_value('my_step_slider')
win.set_step_slider_value('my_step_slider', 75.0)

// 💻 Console Output Log Viewer (dark terminal output log with color-coded logs)
win.add_console_view('app_console', ['[OK] Application started', '[INFO] Database connected'])
win.append_console_log('app_console', '[WARN] Low memory warning')
win.clear_console_log('app_console')

// 📌 Bottom Status Bar (anchored bottom status bar with badge)
win.add_status_bar('app_status', 'Status: Ready | Port: 8080', 'ONLINE')
win.set_status_bar_text('app_status', 'Status: Connected')

// 📍 Context Menu Flyout (right-click popup flyout menu)
win.show_context_menu(x, y, [
	simplegui.ContextMenuItem{
		id: 'ctx_copy'
		title: 'Copy Selection'
		shortcut: 'Ctrl+C'
		on_select: fn (mut win simplegui.SimpleWindow) { ... }
	}
])
win.hide_context_menu()
```

---

## 6. Form RAD Helpers (Label + Widget Pairs)

Pairs a descriptive text label with an input widget in one line of code:

```v
win.add_form_field('Full Name:', 'form_name', 'Ada Lovelace')
win.add_form_password('Password:', 'form_pass', 'secret_key')
win.add_form_search('Search Catalog:', 'form_search', '')
win.add_form_dropdown('Country:', 'form_country', ['USA', 'Canada', 'UK'], 'USA')
win.add_form_switch('Notifications:', 'form_notify', 'Send Email Digest', true)
win.add_form_number('Quantity:', 'form_qty', 1)
win.add_form_slider('Volume:', 'form_vol', 80)
win.add_form_date_picker('Event Date:', 'form_date', '2026-12-25')
win.add_form_time_picker('Start Time:', 'form_time', '09:00')
win.add_form_file_picker('Upload Document:', 'form_file', '/tmp/data.csv')
win.add_form_color_picker('Theme Accent:', 'form_color', '#0a84ff')
win.add_form_progress('Download Progress:', 'form_prog', 45)
```

---

## 7. Nameless RAD Shortcuts

Create controls without defining explicit string IDs:

```v
win.input('Default Text')
input_text := win.get_input()

win.checkbox('Enable auto-update', true)
is_checked := win.get_checkbox()

win.number(10)
num_val := win.get_number()

win.button('Submit Quick Form')
```

---

## 8. Widget Styling & Fluent Method Chaining

Customize width, height, colors, fonts, margins, padding, and tooltips using fluent method chaining on `&Control` or direct `win.set_control_*()` window methods.

### Fluent Chaining Example

```v
mut btn := win.add_button('btn_submit', 'Submit Registration')

btn.set_width(220)
   .set_height(42)
   .set_bg_color('#0a84ff')
   .set_font_color('#ffffff')
   .set_font_size(15)
   .set_font_bold(true)
   .set_corner_radius(8.0)
   .set_border(2.0, '#005bb5')
   .set_margin_xy(10, 5)
   .set_padding_xy(16, 8)
   .set_tooltip('Click to submit your registration form')
```

### Direct Window Setter Reference

```v
win.set_control_width('btn_submit', 220)
win.set_control_height('btn_submit', 42)
win.set_control_size('btn_submit', 220, 42)

win.set_control_font_size('btn_submit', 16)
win.set_control_font_bold('btn_submit', true)
win.set_control_font_color('btn_submit', '#ffffff')

win.set_control_bg_color('btn_submit', '#10b981')
win.set_control_accent_color('btn_submit', '#34c759')
win.set_control_border('btn_submit', 2.0, '#047857')
win.set_control_corner_radius('btn_submit', 6.0)

win.set_control_margin('btn_submit', 10)
win.set_control_margin_xy('btn_submit', 12, 6)
win.set_control_padding_xy('btn_submit', 16, 8)

win.set_control_tooltip('btn_submit', 'Hover helper tip')
win.set_control_visible('btn_submit', true)
win.set_control_enabled('btn_submit', true)
```

---

## 9. Reading & Writing Control Values

### Strings (`get_text` / `set_text`)

```v
username := win.get_text('input_u')
win.set_text('input_u', 'Grace Hopper')
```

### Booleans (`get_bool` / `set_bool`)

```v
is_active := win.get_bool('sw_dark')
win.set_bool('sw_dark', true)
```

### Integers (`get_value_int` / `set_value_int`)

```v
qty := win.get_value_int('num_count')
win.set_value_int('num_count', 42)
```

### Typed Safe Accessors (`get_int`, `get_f64`, `set_int`, `set_f64`)

```v
age := win.get_int('input_age')
win.set_int('input_age', 30)

price := win.get_f64('input_price')
win.set_f64('input_price', 19.99)
```

### Batch Value Operations (`get_all` / `set_all` / `clear_all`)

```v
form_data := win.get_all(['input_name', 'input_email', 'sw_dark'])
println(form_data['input_name'])

win.set_all({
	'input_name': 'Linus Torvalds',
	'input_email': 'linus@kernel.org'
})

win.clear_all(['input_name', 'input_email'])
```

---

## 10. Event Listeners & Callbacks

```v
// Button Click
win.on_click('btn_save', fn (mut win simplegui.SimpleWindow) {
	win.info('Saved', 'Your changes were saved successfully.')
})

// Mouse Hover Enter Listener
win.on_hover('btn_save', fn (mut win simplegui.SimpleWindow) {
	println('Mouse entered / hovered over btn_save')
})

// Double Click Listener (on_dblclick or on_double_click)
win.on_dblclick('card_item', fn (mut win simplegui.SimpleWindow) {
	win.info('Double Clicked', 'Opened item details on double click.')
})
win.on_double_click('card_item', fn (mut win simplegui.SimpleWindow) {
	// Alias syntax for on_dblclick
})

// Right Click Listener (Mouse Secondary Button)
win.on_right_click('card_item', fn (mut win simplegui.SimpleWindow) {
	// Show custom context menu at current mouse position
	mx, my := win.get_mouse_position()
	win.show_context_menu(mx, my, [
		simplegui.ContextMenuItem{ id: 'ctx_edit', title: 'Edit Item' },
		simplegui.ContextMenuItem{ id: 'ctx_del', title: 'Delete Item' },
	])
})

// Value Change
win.on_change('theme_select', fn (mut win simplegui.SimpleWindow) {
	new_theme := win.get_text('theme_select')
	win.set_theme(new_theme)
})

// Enter Key Press
win.on_enter('input_query', fn (mut win simplegui.SimpleWindow) {
	q := win.get_text('input_query')
	println('Submitted search: ${q}')
})

// Table Row Click
win.on_row_click('tbl_users', fn (mut win simplegui.SimpleWindow) {
	selected_row := win.get_table_selected_row('tbl_users')
	println('Clicked row index: ${selected_row}')
})

// Window Close Interceptor
win.on_close(fn (mut win simplegui.SimpleWindow) bool {
	return win.ask('Confirm Quit', 'Are you sure you want to quit the application?')
})

// Global Key Down Listener
win.on_key_down(fn (mut win simplegui.SimpleWindow, key gg.KeyCode) {
	if key == .escape {
		println('Escape key pressed!')
	}
})

// Window Resize Listener
win.on_window_resize(fn (mut win simplegui.SimpleWindow, width int, height int) {
	println('Window resized to: ${width}x${height}')
})
```

---

## 11. RAD Utilities & Form JSON Serialization

### Toast Dialogs

```v
win.info('Success', 'File exported successfully.')
win.warn('Disk Warning', 'Storage space is running low.')
win.error_dialog('Network Error', 'Failed to reach API server.')

if win.ask('Delete Record', 'Are you sure you want to delete this entry?') {
	println('User clicked OK')
}
```

### Batch Control Operations

```v
win.show_controls(['btn_save', 'btn_cancel'])
win.hide_controls(['lbl_loading', 'prog_bar'])

win.enable_controls(['input_u', 'input_p'])
win.disable_controls(['btn_submit'])

win.toggle_visible('panel_extra')
win.toggle_enabled('btn_action')
```

### Form Serialization to JSON

```v
// Export form values to JSON string
json_data := win.export_form_json(['form_name', 'form_email', 'form_notify'])

// Populate form fields from JSON string
win.import_form_json('{"form_name":"Ada","form_email":"ada@vlang.io"}')
```

---

## 12. Reactive State Store & JSON Persistence

Updating a state value automatically triggers registered reactive listeners and updates bound UI controls.

### Setting & Getting Reactive State

```v
win.set_state('user_role', 'Administrator')
win.set_state_int('counter', 42)
win.set_state_bool('dark_mode', true)
win.set_state_f64('font_scale', 1.25)

role := win.get_state('user_role')                    // string
count := win.get_state_int('counter')                 // int
is_dark := win.get_state_bool('dark_mode')           // bool
fallback_role := win.get_state_or('role', 'Guest')   // fallback if key unset

win.toggle_state_bool('dark_mode')        // Toggles boolean state
win.increment_state_int('counter', 1)     // Increments integer state
```

### Reactive State Listeners (`on_state_change`)

```v
win.on_state_change('counter', fn (mut win simplegui.SimpleWindow, val string) {
	win.set_text('lbl_counter_display', 'Current Count: ${val}')
	win.set_text('badge_count', 'Count: ${val}')
})

win.on_state_change('dark_mode', fn (mut win simplegui.SimpleWindow, val string) {
	if val == 'true' {
		win.set_theme('Nord')
	} else {
		win.set_theme('Apple Light')
	}
})
```

### JSON Disk Persistence (`save_state_json` / `load_state_json`)

```v
// Save state store to JSON file
win.save_state_json('app_state.json') or {
	win.error_dialog('Save Error', 'Failed to write app_state.json: ${err}')
}

// Load state store from JSON file (Fires reactive UI listeners!)
win.load_state_json('app_state.json') or {
	win.warn('Load Info', 'No previous app_state.json found.')
}
```

---

## 13. OS System Calls & Hardware API

Cross-platform system helpers (`sys.v`) for command execution, desktop notifications, clipboard, hardware inspection, and path resolution.

### System Commands & Execution

```v
// Synchronous command execution
stdout, exit_code := win.exec('ls -la')

// Execution with fallback string
output := win.exec_or('which git', 'git not installed')

// Background execution
win.exec_bg('ping -c 4 8.8.8.8')

// Timeout execution (milliseconds)
out, code, timed_out := win.exec_timeout('sleep 10', 2000)

// Retry with exponential backoff
res := win.exec_retry('curl -s https://api.ipify.org', 3, 500, 2.0)
println('Output: ${res.output} (Attempts: ${res.attempts})')
```

### Desktop Notifications, Audio & Speech

```v
win.show_system_notification('Backup Complete', 'Your database backup was created successfully.')
win.beep()
win.speak_with_voice('Hello! Welcome to SimpleGUI.', 'Samantha')
```

### Hardware Specs & System Info

```v
cpu_name := win.get_cpu_info()
cpu_cores := win.get_cpu_cores()
memory_ram := win.get_memory_info()
screen_res := win.get_screen_resolution()
battery_pct := win.get_battery_percent()
is_charging := win.is_on_ac_power()
```

### Directories & File Operations

```v
home_path := win.get_system_path('home')
docs_path := win.get_system_path('documents')

win.copy_to_clipboard('Copied text!')
clip_val := win.get_clipboard_text()

win.open_url('https://vlang.io')
win.reveal_in_finder('/tmp/my_folder')
```

---

## 14. V Standard Library Integrations

Built-in wrappers (`stdlib.v`) for V standard library operations.

### HTTP Requests

```v
body := win.http_get('https://api.ipify.org')
response := win.http_post('https://httpbin.org/post', '{"key":"value"}')
```

### Cryptography & Hashes

```v
sha := win.crypto_sha256('secret data')
md5 := win.crypto_md5('secret data')

key := '0123456789abcdef0123456789abcdef'
cipher_hex := win.crypto_encrypt_aes('plain_text', key)
decrypted := win.crypto_decrypt_aes(cipher_hex, key)

hash := win.crypto_bcrypt_hash('my_password') or { '' }
is_valid := win.crypto_bcrypt_verify('my_password', hash)
```

### RegEx & Random Utilities

```v
is_valid_email := win.regex_match('user@domain.com', r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
random_num := win.rand_int(1, 100)
token := win.rand_string(16)
```

### JSON Data Decoding & Performance Stopwatch

```v
data := win.json_decode_map('{"name":"Ada","role":"Admin"}')

mut sw := win.start_stopwatch()
// ... operation ...
elapsed_ms := win.stopwatch_elapsed_ms(sw)
println('Operation completed in ${elapsed_ms} ms')
```

---

## 15. Ergonomic Standalone Functions

Global standalone helper functions in `simplegui`:

```v
simplegui.alert('Title', 'Message dialog')
name := simplegui.prompt('Input Name', 'Default Value')
if simplegui.confirm('Title', 'Confirm action?') { ... }
simplegui.notify('Notification Title', 'Message body')

simplegui.copy_to_clipboard('Text to copy')
clip_text := simplegui.read_clipboard()

simplegui.open_browser('https://vlang.io')
simplegui.quit()
```

---

## 16. Interval Timers & Scheduled Callbacks

`simplegui` provides non-blocking timer capabilities integrated directly into the window rendering loop. You can schedule recurring background callbacks (`set_interval`), one-shot delayed executions (`set_timeout`), pause/resume active timers, and adjust timer intervals dynamically.

### 1. Recurring Interval Timers (`set_interval`)

Triggers a callback function periodically every $N$ milliseconds:

```v
// Update a live clock label every 1000ms (1 second)
win.set_interval('clock_timer', 1000, fn (mut win simplegui.SimpleWindow) {
	t := time.now()
	win.set_text('lbl_clock', 'Current Time: ${t.format_ss()}')
})

// Auto-increment progress bar every 100ms
win.set_interval('progress_timer', 100, fn (mut win simplegui.SimpleWindow) {
	mut val := win.get_value_int('prog_bar')
	val += 2
	if val > 100 { val = 0 }
	win.set_value_int('prog_bar', val)
})

// Alias syntax: add_timer
win.add_timer('stats_poller', 5000, fn (mut win simplegui.SimpleWindow) {
	win.append_console_log('app_console', '[INFO] Periodic system metrics polled.')
})
```

### 2. One-Shot Delayed Timeouts (`set_timeout`)

Executes a callback function once after a specified millisecond delay and automatically unregisters itself:

```v
// Trigger an informational toast after a 3-second delay
win.set_timeout('delayed_alert', 3000, fn (mut win simplegui.SimpleWindow) {
	win.info('Timeout Triggered', '3 seconds have elapsed since button click.')
})
```

### 3. Controlling & Managing Timers

```v
// Pause a running timer (suspends callbacks without deleting registration)
win.pause_timer('progress_timer')

// Start or resume a paused timer
win.start_timer('progress_timer')

// Reset timer tick accumulator (restarts current interval cycle)
win.reset_timer('progress_timer')

// Check if a timer is currently active and running
if win.is_timer_running('progress_timer') {
	println('Progress timer is active')
}

// Dynamically adjust interval frequency (e.g. speed up from 1000ms to 250ms)
win.set_timer_interval('clock_timer', 250)

// Stop and remove a specific timer
win.stop_timer('progress_timer')
win.clear_interval('clock_timer')  // Alias for stop_timer
win.clear_timeout('delayed_alert') // Alias for stop_timer

// Stop and remove all registered timers in the window
win.clear_all_timers()
```

---

## 17. Modern UI & RAD UX Enhancements

`simplegui` includes modern desktop UI enhancements: floating tooltips, backdrop modal overlays, form field validation tags, skeleton loading shimmers, tab badge counters, and search filtering.

### 1. Rich Floating Tooltips
```v
win.add_button('btn_save', 'Save Document')
win.set_control_tooltip('btn_save', 'Click to save your file state')
```

### 2. Backdrop Modal Dialogs (`show_modal`)
```v
win.show_modal(
	'Confirm Action',
	'Are you sure you want to reset all fields?',
	'Reset',
	'Cancel',
	fn (mut win simplegui.SimpleWindow) {
		win.push_toast('Reset', 'All fields cleared', 'info', 2000)
	}
)
win.hide_modal()
```

### 3. Live Form Validation Badges (`set_validation_error`)
```v
win.set_validation_error('input_email', 'Please enter a valid email address with @ domain')
win.clear_validation_error('input_email')
```

### 4. Animated Skeleton Shimmer Placeholders (`add_skeleton`)
```v
// Add animated pulse loading placeholder (Width: 300px, Height: 24px)
win.add_skeleton('sk_user_card', 300, 24)
```

### 5. Tab Badge Counters (`set_tab_badge`)
```v
win.begin_tab_container('main_tabs', ['Overview', 'Messages', 'Settings'])
win.set_tab_badge('main_tabs', 1, '5')    // Adds red badge '[5]' to Messages tab
win.set_tab_badge('main_tabs', 2, 'NEW')  // Adds red badge '[NEW]' to Settings tab
win.end_tab_container()
```

### 6. Live Search Highlighting & Filtering (`set_table_search_filter`)
```v
win.set_table_search_filter('tbl_users', 'Ada')
```

---

## 18. Data & Event Binding (`bind`)

`simplegui` provides ergonomic binding mechanisms to connect UI controls to reactive state keys, handle UI events with concise method chaining, and bind keyboard keys and shortcuts.

### 1. Two-Way Control & Reactive State Store Binding (`bind_state`)

`bind_state` (or alias `bind_control`, `bind_value`) binds a UI control directly to a key in the application state store.
- When `win.set_state(key, val)` is called anywhere in your app, the control value automatically updates in the UI.
- When the user edits or interacts with the control (typing text, toggling a checkbox, moving a slider), the state store key automatically updates!

```v
// 1. Create UI controls
win.add_textbox('input_user', 'Ada Lovelace')
win.add_checkbox('chk_notifications', 'Enable Notifications', true)
win.add_slider('slider_volume', 75)

// 2. Bind controls to state keys (Two-Way Data Binding)
win.bind_state('input_user', 'username')
win.bind_control('chk_notifications', 'notify_enabled')
win.bind_value('slider_volume', 'audio_volume')

// Updating state anywhere in your code automatically syncs the UI control!
win.set_state('username', 'Alan Turing')
win.set_state('notify_enabled', 'false')

// Reading state store gets the live user input!
user := win.get_state('username')
```

### 2. Fluent Event Binding Aliases (`bind_click`, `bind_change`, `bind_event`)

`simplegui` provides fluent `bind_*` event helpers that fit seamlessly into method chaining pipelines:

```v
// Bind click callback
win.bind_click('btn_submit', fn (mut win simplegui.SimpleWindow) {
	win.info('Submitted', 'Form processed successfully!')
})

// Bind value change callback
win.bind_change('theme_picker', fn (mut win simplegui.SimpleWindow) {
	new_theme := win.get_text('theme_picker')
	win.set_theme(new_theme)
})

// Bind Enter key press on input field
win.bind_enter('input_search', fn (mut win simplegui.SimpleWindow) {
	q := win.get_text('input_search')
	println('Search query: ${q}')
})

// Bind hover enter listener
win.bind_hover('card_box', fn (mut win simplegui.SimpleWindow) {
	println('Hovering over card box')
})

// Bind double-click and right-click
win.bind_dblclick('list_item', fn (mut win simplegui.SimpleWindow) {
	println('Item double-clicked')
})
win.bind_right_click('list_item', fn (mut win simplegui.SimpleWindow) {
	println('Context menu requested')
})

// Generic event binding by event name ('click', 'change', 'enter', 'hover', 'dblclick', 'right_click')
win.bind_event('btn_action', 'click', fn (mut win simplegui.SimpleWindow) {
	win.toast('Action executed!')
})
```

### 3. Keyboard Key & Shortcut Binding (`bind_key`, `bind_shortcut`)

Bind individual keyboard keys or named shortcuts to custom callbacks:

```v
// Bind specific key press (e.g. gg.KeyCode.f5 or gg.KeyCode.escape)
win.bind_key(.f5, fn (mut win simplegui.SimpleWindow) {
	win.toast('Refreshed data!')
})

// Bind named shortcut strings ('Escape', 'F1', 'F5', etc.)
win.bind_shortcut('Escape', fn (mut win simplegui.SimpleWindow) {
	win.hide_modal()
})
win.bind_shortcut('F1', fn (mut win simplegui.SimpleWindow) {
	win.info('Help', 'Press Ctrl+K for Command Palette')
})
```

---

## Summary Cheat Sheet Tips

1. **Window Creation**: `win := simplegui.new_simple_window('Title', W, H)`
2. **Set Width / Height**: `win.set_width(900)` or `win.set_size(1024, 768)`
3. **Auto Fit Everything**: Call `win.fit_to_content()` after adding controls so window width/height expand to fit all controls without clipping.
4. **Set Theme**: `win.set_theme('Apple Dark')` or `win.set_theme('Nord')`
5. **No Emojis in UI**: Use standard font characters or brackets like `[Save]`, `[+]`, `[-]` for icon placeholders.
6. **Form RAD Helpers**: Use `win.add_form_field()`, `win.add_form_dropdown()`, and `win.add_form_switch()` to pair labels and controls instantly.
7. **State Management**: Save and load application state with `win.save_state_json()` and `win.load_state_json()` for automatic reactive UI synchronization.
8. **Interval Timers & Timeouts**: Schedule background tasks or delayed actions with `win.set_interval('id', 1000, cb)` and `win.set_timeout('id', 3000, cb)`.
9. **Execution Loop**: End your script with `win.run()` to start the app.
