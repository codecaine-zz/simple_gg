# ⚡ SimpleGUI (`simple_gg`) - Beginner & RAD Cheat Sheet API Guide

`simplegui` (in package `simple_gg`) is a lightweight, zero-dependency, Rapid Application Development (RAD) UI toolkit for building desktop applications in V using V's native `gg` graphics engine.

Whether you're building a 5-minute utility tool, a multi-tab admin panel, or an interactive data app, `simplegui` lets you create sleek interfaces with concise code, rich built-in themes, reactive state management, and OS system calls.

---

## 🚀 60-Second Copy-Paste Starter App

Copy this complete example into a `main.v` file and run `v run .` to launch your first desktop app:

```v
module main

import simplegui

fn main() {
	// 1. Create a modern window (Width: 640px, Height: 480px)
	mut win := simplegui.new_simple_window('⚡ Quick Profile Editor', 640, 480)
	
	// 2. Pick a stylish dark theme (Nord, Apple Dark, Dracula, Cyberpunk, etc.)
	win.set_theme('Apple Dark')

	// 3. Add UI Headings & Labeled Form Fields (RAD Ergonomics)
	win.add_heading('👤 User Profile Settings')
	win.add_form_field('Full Name:', 'input_name', 'Ada Lovelace')
	win.add_form_field('Email Address:', 'input_email', 'ada@vlang.io')
	win.add_checkbox('chk_newsletter', 'Subscribe to Monthly Tech Digest', true)

	// 4. Add Buttons inside a Horizontal Row
	win.begin_row('action_row')
	win.add_button('btn_save', '💾 Save Profile')
	win.add_button('btn_reset', '↺ Reset Fields')
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

## 📚 Quick Navigation Index

1. [Window Setup & Configuration](#1-window-setup--configuration)
2. [Built-in Themes & Styling](#2-built-in-themes--styling)
3. [Layout Containers & Grouping](#3-layout-containers--grouping)
4. [Widget Styling & Fluent Chaining](#4-widget-styling--fluent-chaining)
5. [Complete Widget Reference](#5-complete-widget-reference)
6. [Form RAD Helpers (Label + Widget)](#6-form-rad-helpers-label--widget)
7. [Nameless RAD Shortcuts](#7-nameless-rad-shortcuts)
8. [Reading & Writing Control Values](#8-reading--writing-control-values)
9. [Event Listeners & Event Callbacks](#9-event-listeners--event-callbacks)
10. [RAD Utilities & System Notifications](#10-rad-utilities--system-notifications)
11. [Developer & Advanced UI Controls](#11-developer--advanced-ui-controls)
12. [Reactive State Store & JSON Persistence](#12-reactive-state-store--json-persistence)
13. [OS System Calls & Hardware API](#13-os-system-calls--hardware-api)
14. [V Standard Library Integrations](#14-v-standard-library-integrations)

---

## 1. Window Setup & Configuration

### Create Window

```v
// Create a standard window with Title, Width, and Height
mut win := simplegui.new_simple_window('My Desktop App', 800, 600)

// Alias syntax (identical functionality)
mut win2 := simplegui.new_window('My Desktop App', 800, 600)
```

### Window Dimensions & Full Screen

```v
// Resize window programmatically
win.set_size(1024, 768)

// Lock window to fixed dimensions (prevents user resizing)
win.set_fixed_size(500, 400)

// Toggle or enable Full Screen mode
win.set_fullscreen(true)     // Enable full screen window
win.toggle_fullscreen()      // Toggle full screen state
is_fs := win.is_fullscreen() // Returns true if currently full screen

// Quick size presets: 'small', 'medium', 'large', 'hd', 'full_hd', 'dialog', 'settings', 'login'
win.set_size_preset('hd') // Resizes to 1280x720
```

### Window Constraints & Customization

```v
// Set title bar text dynamically
win.set_title('Updated App Window Title')

// Set minimum and maximum window boundaries
win.set_min_size(400, 300)
win.set_max_size(1920, 1080)

// Adjust outer edge padding (default: 16px)
win.set_padding(24)

// Adjust vertical widget spacing (default: 10px)
win.set_spacing(12)

// Keep window floated on top of all other desktop applications
win.set_always_on_top(true)

// Set window background opacity (0.0 transparent to 1.0 opaque)
win.set_opacity(0.95)

// Enable or disable Cmd+Q / Ctrl+Q hotkey exit shortcut
win.set_close_shortcut_enabled(true)
```

### RAD Window Presets (Dialogs & Splash Screens)

```v
// Create a centered non-resizable dialog window
mut dialog := simplegui.new_simple_window('Dialog', 420, 220).make_fixed_dialog('Confirm Action', 420, 220)

// Create a borderless splash screen window
mut splash := simplegui.new_simple_window('Splash', 500, 300).make_splash_screen(500, 300)

// Create a slim floating utility panel
mut panel := simplegui.new_simple_window('Panel', 300, 600).make_utility_panel()
```

### Window Lifecycle

```v
// Close window programmatically
win.close()
// OR
win.quit()

// Start the window execution loop (blocks main thread until closed)
win.run()
```

---

## 2. Built-in Themes & Styling

`simplegui` includes 17 curated light and dark themes. Setting a theme instantly updates all controls, fonts, hover states, cards, and background colors.

```v
// Apply a theme by name
win.set_theme('Nord')

// Toggle between Apple Light and Apple Dark themes
win.toggle_window_theme()

// List all available theme names as an array of strings
themes := simplegui.list_themes()
// ['Apple Light', 'Apple Dark', 'Nord', 'Dracula', 'Cyberpunk', 'Catppuccin Mocha', ...]

// Get Theme struct by alias
theme := simplegui.get_theme('dark') // Accepts 'dark', 'nord', 'cyberpunk', 'github', etc.
```

### Themes Reference Table

| Theme Name | Style Description | Background | Accent Color | Type |
| :--- | :--- | :--- | :--- | :--- |
| **`Apple Light`** | Default clean macOS light mode | `#ffffff` | `#007aff` | Light |
| **`Apple Dark`** | Modern macOS dark mode | `#1c1c1e` | `#0a84ff` | Dark |
| **`Nord`** | Cool arctic frost blue palette | `#2e3440` | `#88c0d0` | Dark |
| **`Dracula`** | Classic vampire dark purple | `#282a36` | `#bd93f9` | Dark |
| **`Cyberpunk`** | High-contrast neon dark vibe | `#0d0d15` | `#ff007f` | Dark |
| **`Catppuccin Mocha`** | Smooth pastel dark theme | `#1e1e2e` | `#cba6f7` | Dark |
| **`GitHub Dark`** | Official GitHub dark mode | `#0d1117` | `#58a6ff` | Dark |
| **`GitHub Light`** | Official GitHub light mode | `#ffffff` | `#0969da` | Light |
| **`Sonoma Emerald`** | Dark forest glass layout | `#0d1f18` | `#30d158` | Dark |
| **`Ventura Amber`** | Warm sunset dark palette | `#211815` | `#ff9500` | Dark |

---

## 3. Layout Containers & Grouping

Organize controls easily using rows, grids, tabbed panels, split views, and group boxes.

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
// 3 columns with 12px gap between columns
win.begin_grid('gallery_grid', 3, 12)
win.add_button('g1', 'Card 1')
win.add_button('g2', 'Card 2')
win.add_button('g3', 'Card 3')
win.add_button('g4', 'Card 4')
win.add_button('g5', 'Card 5')
win.add_button('g6', 'Card 6')
win.end_grid()
```

### 3. Tabbed Container (`begin_tab_container` / `end_tab_container`)

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

### 4. Split Pane View (`begin_split_view` / `end_split_view`)

Splits the container into a left sidebar and right main content region:

```v
// Left sidebar takes 30% width, right content takes 70%
win.begin_split_view('sidebar_split', 30)

// Left Region (Sidebar)
win.add_heading('Navigation')
win.add_button('nav_home', '🏠 Home')
win.add_button('nav_settings', '⚙️ Settings')

// Right Region (Main Area)
win.add_heading('Main Dashboard Content')
win.add_label('lbl_dash', 'Select an option from the left sidebar.')

win.end_split_view()
```

### 5. Group Box Card (`group` / `begin_group`)

Wraps widgets in a visual card container with a title:

```v
win.group('grp_account', '🔒 User Credentials', fn (mut win simplegui.SimpleWindow) {
	win.add_form_field('Username:', 'input_u', 'admin')
	win.add_form_password('Password:', 'input_p', 'secret123')
})
```

---

## 4. Widget Styling & Fluent Chaining

Customize any control's width, height, colors, fonts, margins, padding, and tooltips using fluent method chaining on `&Control` or direct `win.set_control_*()` methods.

### Method Chaining Example

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
// Width & Height
win.set_control_width('btn_submit', 220)
win.set_control_height('btn_submit', 42)
win.set_control_size('btn_submit', 220, 42)

// Font & Typography
win.set_control_font_size('btn_submit', 16)
win.set_control_font_bold('btn_submit', true)
win.set_control_font_color('btn_submit', '#ffffff')

// Background & Borders
win.set_control_bg_color('btn_submit', '#10b981')
win.set_control_accent_color('btn_submit', '#34c759')
win.set_control_border('btn_submit', 2.0, '#047857')
win.set_control_corner_radius('btn_submit', 6.0)

// Margins (Outer spacing) & Padding (Inner spacing)
win.set_control_margin('btn_submit', 10)         // Margin all sides
win.set_control_margin_xy('btn_submit', 12, 6)   // Margin X and Y
win.set_control_padding_xy('btn_submit', 16, 8)  // Padding X and Y

// Tooltips, Visibility, and Enabled State
win.set_control_tooltip('btn_submit', 'Hover helper tip')
win.set_control_visible('btn_submit', true)
win.set_control_enabled('btn_submit', true)
```

---

## 5. Complete Widget Reference

Every widget is created with a unique `name` string identifier.

### Text Labels & Dividers

```v
// Static text label
win.add_label('lbl_status', 'Status: System Ready')

// Bold section title
win.add_heading('Database Configuration')

// Divider line with label
win.add_divider('Optional Settings')
```

### Buttons

```v
// Standard Push Button
win.add_button('btn_run', '▶️ Run Processing')

// Click Handler
win.on_click('btn_run', fn (mut win simplegui.SimpleWindow) {
	win.info('Started', 'Processing job launched!')
})
```

### Inputs, Passwords & Textareas

```v
// Text Input
win.add_input('input_host', 'localhost')

// Password Input (masked text)
win.add_password('input_secret', 'my_pass_123')

// Multi-line Text Area
win.add_textarea('input_logs', 'Line 1: Started\nLine 2: Ready')
```

### Search Bar

Includes a search `🔍` icon and an instant clear `✕` button:

```v
win.add_search_bar('search_box', 'Type to search records...')

// Handle Enter key inside search bar
win.on_enter('search_box', fn (mut win simplegui.SimpleWindow) {
	query := win.get_text('search_box')
	println('Search query submitted: ${query}')
})
```

### Checkboxes & Toggle Switches

```v
// Checkbox
win.add_checkbox('chk_debug', 'Enable Verbose Logging', false)

// Horizontal Switch
win.add_switch('sw_dark', 'Dark Theme Mode', true)
```

### Numeric Steppers & Sliders

```v
// Number Stepper (with Up ▲ / Down ▼ buttons)
win.add_number('num_count', 5)

// Range Slider (0 to 100)
win.add_slider('slider_vol', 75)
```

### Dropdowns & Segmented Controls

```v
// Dropdown Selector
win.add_dropdown('drop_role', ['Administrator', 'Developer', 'Guest'], 'Developer')

// Segmented Control (Pill Button Selector)
win.add_segmented_control('seg_view', ['Grid View', 'List View', 'Map'], 'Grid View')
```

### Interactive Data Table

Supports sorting by header clicks, mouse-wheel scrolling, and row selections:

```v
headers := ['ID', 'Full Name', 'Role', 'Status']
rows := [
	['1', 'Ada Lovelace', 'Mathematician', 'Active'],
	['2', 'Alan Turing', 'Cryptanalyst', 'Active'],
	['3', 'Grace Hopper', 'Computer Scientist', 'Offline'],
]

// Add Data Table
win.add_table('tbl_users', headers, rows)
win.set_control_height('tbl_users', 200) // Fixed height enables vertical scrolling

// Sort Table programmatically by Column 1 (Full Name) ascending
win.sort_table('tbl_users', 1, true)

// Handle Row Selection
win.on_row_click('tbl_users', fn (mut win simplegui.SimpleWindow) {
	selected_row_idx := win.get_table_selected_row('tbl_users')
	println('Selected row index: ${selected_row_idx}')
})
```

### Badges, Breadcrumbs & Steppers

```v
// Colored Status Badge ('success', 'warning', 'danger', 'info')
win.add_badge('badge_status', 'ONLINE', 'success')

// Breadcrumb Navigation Path
win.add_breadcrumb('nav_path', ['Home', 'Projects', 'SimpleGUI', 'Settings'])

// Multi-step Wizard Indicator (0-indexed step)
win.add_stepper('step_wizard', ['Account Details', 'Billing', 'Review'], 1)
```

### Accordions, Avatars & Ratings

```v
// Collapsible Accordion Box
win.add_accordion('acc_faq', 'Frequently Asked Questions', 'SimpleGUI runs natively on macOS, Windows, and Linux.', false)

// User Avatar Circle
win.add_avatar('user_avatar', 'AL', 'Ada Lovelace')

// Interactive 5-Star Rating
win.add_rating('star_score', 4)
```

### Pickers & Utilities

```v
// Date Picker Field
win.add_date_picker('input_date', '2026-08-11')

// Time Picker Field
win.add_time_picker('input_time', '14:30')

// File Picker Field (Input + Browse button)
win.add_file_picker('input_file', 'Choose File:', '/tmp/document.pdf')

// Color Swatch Well
win.add_color_well('swatch_accent', '#0a84ff')

// Progress Bar (0 to 100%)
win.add_progress_indicator('prog_bar', 65)

// Metric KPI Card
win.add_metric_card('kpi_sales', 'Total Revenue', '$48,250', '+14.2%', 'vs last month')
```

---

## 6. Form RAD Helpers (Label + Widget)

Form helpers automatically pair a descriptive text label with an input widget in one clean line of code:

```v
// 1. Labeled Text Field
win.add_form_field('Full Name:', 'form_name', 'Ada Lovelace')

// 2. Labeled Password Field
win.add_form_password('Password:', 'form_pass', 'secret_key')

// 3. Labeled Search Field
win.add_form_search('Search Catalog:', 'form_search', '')

// 4. Labeled Dropdown
win.add_form_dropdown('Country:', 'form_country', ['USA', 'Canada', 'UK'], 'USA')

// 5. Labeled Switch Toggle
win.add_form_switch('Notifications:', 'form_notify', 'Send Email Digest', true)

// 6. Labeled Number Stepper
win.add_form_number('Quantity:', 'form_qty', 1)

// 7. Labeled Range Slider
win.add_form_slider('Volume:', 'form_vol', 80)

// 8. Labeled Date Picker
win.add_form_date_picker('Event Date:', 'form_date', '2026-12-25')

// 9. Labeled Time Picker
win.add_form_time_picker('Start Time:', 'form_time', '09:00')

// 10. Labeled File Picker
win.add_form_file_picker('Upload Document:', 'form_file', '/tmp/data.csv')

// 11. Labeled Color Picker
win.add_form_color_picker('Theme Accent:', 'form_color', '#0a84ff')

// 12. Labeled Progress Bar
win.add_form_progress('Download Progress:', 'form_prog', 45)
```

---

## 7. Nameless RAD Shortcuts

For quick one-off dialogs and prototype scripts, create controls without defining explicit string IDs:

```v
// Nameless Text Input
win.input('Default Text')
input_text := win.get_input()

// Nameless Checkbox
win.checkbox('Enable auto-update', true)
is_checked := win.get_checkbox()

// Nameless Number Stepper
win.number(10)
num_val := win.get_number()

// Nameless Button
win.button('Submit Quick Form')
```

---

## 8. Reading & Writing Control Values

### Strings (`get_text` / `set_text`)

Works on inputs, labels, textareas, dropdowns, badges, search fields, date pickers, and buttons:

```v
// Read string value
username := win.get_text('input_u')

// Set string value
win.set_text('input_u', 'Grace Hopper')
```

### Booleans (`get_bool` / `set_bool`)

Works on checkboxes, switches, and toggles:

```v
// Read boolean state
is_active := win.get_bool('sw_dark')

// Update boolean state
win.set_bool('sw_dark', true)
```

### Integers (`get_value_int` / `set_value_int`)

Works on number steppers, sliders, progress bars, ratings, and steppers:

```v
// Read integer value
qty := win.get_value_int('num_count')

// Set integer value
win.set_value_int('num_count', 42)
```

### Typed Safe Accessors (`get_int`, `get_f64`, `set_int`, `set_f64`)

Safely parses text inputs into numerical types:

```v
// Read / Set Integer
age := win.get_int('input_age')
win.set_int('input_age', 30)

// Read / Set Float 64
price := win.get_f64('input_price')
win.set_f64('input_price', 19.99)
```

### Batch Value Operations (`get_all` / `set_all` / `clear_all`)

```v
// Read multiple control values into a map[string]string
form_data := win.get_all(['input_name', 'input_email', 'sw_dark'])
println(form_data['input_name'])

// Populate multiple controls at once from a map[string]string
win.set_all({
	'input_name': 'Linus Torvalds',
	'input_email': 'linus@kernel.org'
})

// Clear text across multiple controls
win.clear_all(['input_name', 'input_email'])
```

---

## 9. Event Listeners & Event Callbacks

### 1. Button Click (`on_click`)

```v
win.add_button('btn_save', 'Save Changes')
win.on_click('btn_save', fn (mut win simplegui.SimpleWindow) {
	win.info('Saved', 'Your changes were saved successfully.')
})
```

### 2. Control Value Change (`on_change`)

Triggers whenever text is typed, a checkbox is toggled, a slider is dragged, or a dropdown option is picked:

```v
win.add_dropdown('theme_select', ['Apple Light', 'Nord', 'Dracula'], 'Nord')

win.on_change('theme_select', fn (mut win simplegui.SimpleWindow) {
	new_theme := win.get_text('theme_select')
	win.set_theme(new_theme)
})
```

### 3. Enter Key Press (`on_enter`)

Triggers when the user presses `Enter` inside a text input or search bar:

```v
win.add_input('input_query', '')
win.on_enter('input_query', fn (mut win simplegui.SimpleWindow) {
	q := win.get_text('input_query')
	println('Submitted search: ${q}')
})
```

### 4. Table Row Selection (`on_row_click`)

```v
win.on_row_click('tbl_users', fn (mut win simplegui.SimpleWindow) {
	selected_row := win.get_table_selected_row('tbl_users')
	println('Clicked row index: ${selected_row}')
})
```

### 5. Window Close Interceptor (`on_close`)

Intercepts `Cmd+Q`, `Ctrl+Q`, or closing the titlebar window button:

```v
win.on_close(fn (mut win simplegui.SimpleWindow) bool {
	// Return true to allow window closing, or false to abort closing
	return win.ask('Confirm Quit', 'Are you sure you want to quit the application?')
})
```

### 6. Global Key Down Listener (`on_key_down`)

```v
win.on_key_down(fn (mut win simplegui.SimpleWindow, key gg.KeyCode) {
	if key == .escape {
		println('Escape key pressed!')
	}
})
```

### 7. Window Resize Listener (`on_window_resize`)

```v
win.on_window_resize(fn (mut win simplegui.SimpleWindow, width int, height int) {
	println('Window resized to: ${width}x${height}')
})
```

---

## 10. RAD Utilities & System Notifications

### Dialogs & Toast Notifications

```v
// Information Toast Alert
win.info('Success', 'File exported successfully.')

// Warning Toast Alert
win.warn('Disk Warning', 'Storage space is running low.')

// Error Toast Alert
win.error_dialog('Network Error', 'Failed to reach API server.')

// System Confirmation Prompt (returns true if confirmed)
if win.ask('Delete Record', 'Are you sure you want to delete this entry?') {
	println('User clicked OK')
}
```

### Batch Control Operations

```v
// Show or Hide multiple controls at once
win.show_controls(['btn_save', 'btn_cancel'])
win.hide_controls(['lbl_loading', 'prog_bar'])

// Enable or Disable multiple controls at once
win.enable_controls(['input_u', 'input_p'])
win.disable_controls(['btn_submit'])

// Toggle single control state
win.toggle_visible('panel_extra') // Returns new visibility bool
win.toggle_enabled('btn_action')  // Returns new enabled bool
```

### Form Serialization to JSON

```v
// Export form values to a JSON string
json_data := win.export_form_json(['form_name', 'form_email', 'form_notify'])

// Populate form fields from a JSON string
win.import_form_json('{"form_name":"Ada","form_email":"ada@vlang.io"}')
```

---

## 11. Developer & Advanced UI Controls

### Toolbar with Icon Buttons

```v
win.add_toolbar('main_tb', [
	simplegui.ToolbarItem{
		icon: '📄'
		tooltip: 'New Document'
		on_click: fn (mut win simplegui.SimpleWindow) {
			win.info('New', 'Created new file')
		}
	},
	simplegui.ToolbarItem{
		icon: '💾'
		tooltip: 'Save Document'
		on_click: fn (mut win simplegui.SimpleWindow) {
			win.info('Saved', 'File saved')
		}
	},
])
```

### Hyperlink Control

```v
// Clickable link text that opens a web browser URL
win.add_link('link_docs', '🌐 Open Official V Language Documentation', 'https://vlang.io')
```

### Dropdown Action Menu

```v
// Click to open an expanding popup action list
win.add_menu_button('menu_actions', 'Actions ▾', ['Export PDF', 'Export CSV', 'Print', 'Delete'])

win.on_change('menu_actions', fn (mut win simplegui.SimpleWindow) {
	selected_action := win.get_menu_selected('menu_actions')
	win.info('Menu Clicked', 'You selected: ${selected_action}')
})
```

### Multi-Select Checklist & Tag Chip Group

```v
// Checklist
win.add_checklist('chk_perms', ['Read', 'Write', 'Execute', 'Admin'], ['Read', 'Write'])
selected_perms := win.get_checklist_selected('chk_perms')

// Tag Chip Group
win.add_chip_group('chips_tags', ['Bug', 'Feature', 'Documentation', 'UX'], ['Bug'])
selected_tags := win.get_chip_selected('chips_tags')
```

### Password Strength Meter

```v
// Attach a strength meter directly to a password input box by control name
win.add_form_password('Create Password:', 'input_user_pwd', '')
win.add_password_strength('pwd_meter', 'input_user_pwd')
```

---

## 12. Reactive State Store & JSON Persistence

`simplegui` includes a built-in reactive key-value state store (`state.v`). Updating a state value automatically triggers all registered reactive listeners and updates bound UI controls across the window.

### Setting & Getting Reactive State

```v
// Set state key-value pairs
win.set_state('user_role', 'Administrator')
win.set_state_int('counter', 42)
win.set_state_bool('dark_mode', true)
win.set_state_f64('font_scale', 1.25)

// Get state values
role := win.get_state('user_role')                    // returns string
count := win.get_state_int('counter')                 // returns int
is_dark := win.get_state_bool('dark_mode')           // returns bool
fallback_role := win.get_state_or('role', 'Guest')   // returns fallback if key unset

// State mutations
win.toggle_state_bool('dark_mode')        // Toggles boolean state
win.increment_state_int('counter', 1)     // Increments integer state by delta
```

### Reactive State Listeners (`on_state_change`)

```v
// Listen for state key changes and update UI reactively
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
// Save current state store to a JSON file on disk
win.save_state_json('app_state.json') or {
	win.error_dialog('Save Error', 'Failed to write app_state.json: ${err}')
}

// Load state store from JSON file (Automatically fires all reactive UI listeners!)
win.load_state_json('app_state.json') or {
	win.warn('Load Info', 'No previous app_state.json found.')
}
```

---

## 13. OS System Calls & Hardware API

`simplegui` provides cross-platform system helpers (`sys.v`) for command execution, desktop notifications, audio, clipboard, hardware inspection, and path resolution.

### System Commands & Execution

```v
// Synchronously run a shell command (returns stdout string and exit code int)
stdout, exit_code := win.exec('ls -la')

// Run command with fallback string on failure
output := win.exec_or('which git', 'git not installed')

// Run command in background asynchronously
win.exec_bg('ping -c 4 8.8.8.8')

// Run command with timeout in milliseconds
out, code, timed_out := win.exec_timeout('sleep 10', 2000)

// Run command with automatic retries and exponential backoff
res := win.exec_retry('curl -s https://api.ipify.org', 3, 500, 2.0)
println('Command output: ${res.output} (Attempts: ${res.attempts})')
```

### Desktop Notifications, Audio & Speech

```v
// Trigger OS Desktop Notification Banner (macOS / Windows / Linux)
win.show_system_notification('Backup Complete', 'Your database backup was created successfully.')

// Play System Alert Beep
win.beep()

// Text-to-Speech Voice Synthesis
win.speak_with_voice('Hello! Welcome to SimpleGUI.', 'Samantha')
```

### Hardware Specs & System Information

```v
cpu_name := win.get_cpu_info()          // e.g. "Apple M4 Pro"
cpu_cores := win.get_cpu_cores()        // e.g. 14
memory_ram := win.get_memory_info()     // e.g. "48.0 GB RAM"
screen_res := win.get_screen_resolution() // e.g. "1920 x 1080"
battery_pct := win.get_battery_percent() // Returns integer 0..100 (-1 if no battery)
is_charging := win.is_on_ac_power()      // Returns true if plugged in
```

### System Directories & System Utilities

```v
// System Directories ('home', 'desktop', 'documents', 'downloads', 'tmp', 'app')
home_path := win.get_system_path('home')
docs_path := win.get_system_path('documents')

// Clipboard Operations
win.copy_to_clipboard('Copied text!')
clip_val := win.get_clipboard_text()

// Open URL or Reveal File in Desktop Finder / File Explorer
win.open_url('https://vlang.io')
win.reveal_in_finder('/tmp/my_folder')
```

---

## 14. V Standard Library Integrations

`simplegui` includes built-in wrappers (`stdlib.v`) for V's standard library modules.

### HTTP Requests

```v
// HTTP GET request
body := win.http_get('https://api.ipify.org')

// HTTP POST request with JSON payload
response := win.http_post('https://httpbin.org/post', '{"key":"value"}')
```

### Cryptography & Hashes

```v
// SHA256 & MD5 Hashes
sha := win.crypto_sha256('secret data')
md5 := win.crypto_md5('secret data')

// AES Symmetric Encryption & Decryption
key := '0123456789abcdef0123456789abcdef' // 32-byte key
cipher_hex := win.crypto_encrypt_aes('plain_text', key)
decrypted := win.crypto_decrypt_aes(cipher_hex, key)

// Bcrypt Password Hashing & Verification
hash := win.crypto_bcrypt_hash('my_password') or { '' }
is_valid := win.crypto_bcrypt_verify('my_password', hash)
```

### RegEx & Random Generators

```v
// RegEx Match
is_valid_email := win.regex_match('user@domain.com', r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')

// Random Number & Random Token String
random_num := win.rand_int(1, 100)
token := win.rand_string(16)
```

### JSON Data Decoding & Benchmarking

```v
// Parse JSON string into map[string]string
data := win.json_decode_map('{"name":"Ada","role":"Admin"}')
println(data['name'])

// Stopwatch Performance Timing
mut sw := win.start_stopwatch()
// ... perform heavy operation ...
elapsed_ms := win.stopwatch_elapsed_ms(sw)
println('Operation completed in ${elapsed_ms} ms')
```

---

## 💡 Summary Cheat Sheet Tips

1. **Window Creation**: `win := simplegui.new_simple_window('Title', W, H)`
2. **Set Theme**: `win.set_theme('Apple Dark')` or `win.set_theme('Nord')`
3. **Form RAD Helpers**: Use `win.add_form_field()`, `win.add_form_dropdown()`, and `win.add_form_switch()` to pair labels and controls instantly.
4. **Layout**: Group items horizontally with `win.begin_row()` / `win.end_row()` or into tabs with `win.begin_tab_container()`.
5. **State**: Save and load application state with `win.save_state_json()` and `win.load_state_json()` for automatic reactive UI synchronization.
6. **Execution**: End your script with `win.run()` to start the app.
