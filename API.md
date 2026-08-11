# ⚡ SimpleGUI (`simple_gg`) Cheat Sheet & API Guide

`simplegui` is a lightweight, beginner-friendly UI framework for building cross-platform desktop applications in V using V's built-in `gg` graphics library.

This cheat sheet contains **ready-to-copy code snippets** for every function, widget, container, styling helper, and event listener in `simplegui`.

---

## 🚀 Quick Copy-Paste Starter App

Copy this snippet into `main.v` and run `v run .` to get started instantly:

```v
module main

import simplegui

fn main() {
	// 1. Create Window
	mut win := simplegui.new_simple_window('My First App', 640, 480)
	win.set_theme('Apple Dark')

	// 2. Add Widgets
	win.add_heading('Welcome to SimpleGUI')
	win.add_form_field('Your Name:', 'username', 'Ada Lovelace')
	win.add_checkbox('agree', 'I agree to the terms', true)
	win.add_button('btn_save', 'Save Profile')

	// 3. Handle Button Click
	win.on_click('btn_save', fn (mut win simplegui.SimpleWindow) {
		name := win.get_text('username')
		agreed := win.get_bool('agree')
		win.info('Profile Saved', 'Hello ${name}! Agreed: ${agreed}')
	})

	// 4. Run Application
	win.run()
}
```

---

## 📚 Cheat Sheet Table of Contents

1. [Window Setup & Configuration](#1-window-setup--configuration)
2. [Themes & Color Palettes](#2-themes--color-palettes)
3. [Layouts & Containers](#3-layouts--containers)
4. [Control Customization & Fluent Styling](#4-control-customization--fluent-styling)
5. [UI Widgets & Controls](#5-ui-widgets--controls)
6. [Form Field Helpers](#6-form-field-helpers)
7. [Nameless Control Shortcuts](#7-nameless-control-shortcuts)
8. [Reading & Writing Values](#8-reading--writing-values)
9. [Event Handling & Callbacks](#9-event-handling--callbacks)
10. [RAD Development & System Utilities](#10-rad-development--system-utilities)
11. [More Developer & User-Requested Controls](#11-more-developer--user-requested-controls)

---

## 1. Window Setup & Configuration

### Create a New Window

```v
mut win := simplegui.new_simple_window('App Title', 800, 600)
```

### Set Window Title

```v
win.set_title('New App Title')
```

### Set Window Dimensions

```v
win.set_size(1024, 768)
```

### Lock Fixed Window Size (Non-resizable)

```v
win.set_fixed_size(400, 300)
```

### Use Size Presets (`'small'`, `'medium'`, `'large'`, `'hd'`, `'dialog'`, `'login'`, `'settings'`)

```v
win.set_size_preset('medium')
```

### Set Minimum & Maximum Window Constraints

```v
win.set_min_size(400, 300)
win.set_max_size(1920, 1080)
```

### Set Inner Window Padding

```v
win.set_padding(20) // 20px padding around all edges
```

### Set Default Vertical Spacing Between Controls

```v
win.set_spacing(12) // 12px vertical spacing between widgets
```

### Keep Window Always On Top

```v
win.set_always_on_top(true)
```

### Set Window Opacity (Transparency `0.0`–`1.0`)

```v
win.set_opacity(0.95)
```

### Enable/Disable Keyboard Quit Shortcut (`Cmd+Q` / `Ctrl+Q`)

```v
win.set_close_shortcut_enabled(true)
```

### Enable Debug Logs & Footer Bar

```v
win.set_debug_mode(true)
```

### Display Floating Toast Notification

```v
win.show_toast('Notification Title', 'Operation finished successfully!')
```

### Preset Window Builders

```v
// Centered non-resizable dialog window
mut dialog := simplegui.new_simple_window('Confirm', 400, 200).make_fixed_dialog('Confirm', 400, 200)

// Borderless splash screen
mut splash := simplegui.new_simple_window('Loading', 500, 300).make_splash_screen(500, 300)

// Floating utility tool window
mut utility := simplegui.new_simple_window('Tools', 300, 500).make_utility_panel()
```

### Programmatically Close Window

```v
win.close()
// OR
win.quit()
```

### Run Window Event Loop

```v
win.run()
```

---

## 2. Themes & Color Palettes

`simplegui` includes 17 built-in production themes. Setting a theme dynamically updates all widget colors, borders, font colors, and backgrounds.

### Apply Built-in Theme

```v
win.set_theme('Apple Dark')
```

### Toggle Light / Dark Mode

```v
win.toggle_window_theme()
```

### List All Available Theme Names

```v
theme_names := simplegui.list_themes()
println(theme_names) // ['Apple Light', 'Apple Dark', 'Nord', 'Dracula', ...]
```

### Look Up Theme by Name or Short Alias

```v
dark_theme := simplegui.get_theme('dark') // accepts 'dark', 'nord', 'cyberpunk', etc.
```

### Apply Custom Theme Struct

```v
custom_theme := simplegui.Theme{
	name: 'My Custom Theme'
	bg_color: simplegui.parse_hex_color('#1e1e2e')
	panel_bg: simplegui.parse_hex_color('#2a2a3c')
	text_color: simplegui.parse_hex_color('#ffffff')
	accent_color: simplegui.parse_hex_color('#a6e3a1')
}
win.apply_theme(custom_theme)
```

### Theme Quick Reference Table

| Theme Name                | Style / Vibe                | Background | Accent    | Mode  |
| :------------------------ | :-------------------------- | :--------- | :-------- | :---- |
| **`Apple Light`**         | Default macOS light theme   | `#ffffff`  | `#007aff` | Light |
| **`Apple Dark`**          | Modern macOS dark mode      | `#1c1c1e`  | `#0a84ff` | Dark  |
| **`Midnight Space Gray`** | Pro dark titanium gray      | `#161618`  | `#0a84ff` | Dark  |
| **`Nord`**                | Arctic frost dark palette   | `#2e3440`  | `#88c0d0` | Dark  |
| **`Dracula`**             | Classic vampire dark purple | `#282a36`  | `#bd93f9` | Dark  |
| **`Cyberpunk`**           | High-contrast neon dark     | `#0d0d15`  | `#ff007f` | Dark  |
| **`Catppuccin Mocha`**    | Pastel dark theme           | `#1e1e2e`  | `#cba6f7` | Dark  |
| **`GitHub Dark`**         | Official GitHub dark theme  | `#0d1117`  | `#58a6ff` | Dark  |
| **`GitHub Light`**        | Official GitHub light theme | `#ffffff`  | `#0969da` | Light |
| **`Solarized Dark`**      | Solarized dark palette      | `#002b36`  | `#2aa198` | Dark  |
| **`Solarized Light`**     | Solarized light palette     | `#fdf6e3`  | `#268bd2` | Light |
| **`Sonoma Emerald`**      | Dark forest green glass     | `#0d1f18`  | `#30d158` | Dark  |
| **`Ventura Amber`**       | Sunset amber dark mode      | `#211815`  | `#ff9500` | Dark  |
| **`Navy Blue`**           | Slate navy theme            | `#0f172a`  | `#38bdf8` | Dark  |
| **`Forest Green`**        | Deep green palette          | `#14532d`  | `#4ade80` | Dark  |
| **`Apple Sunset`**        | Mojave twilight dark theme  | `#281a24`  | `#ff6b00` | Dark  |
| **`Soft Pastel`**         | Soft warm studio light      | `#faf6f0`  | `#e07a5f` | Light |

---

## 3. Layouts & Containers

### Side-by-Side Horizontal Row

```v
win.begin_row('button_row')
win.add_button('save_btn', 'Save')
win.add_button('cancel_btn', 'Cancel')
win.end_row()
```

### Multi-Column Grid Layout

```v
// 3 columns with 10px column spacing
win.begin_grid('my_grid', 3, 10)
win.add_button('g1', 'Item 1')
win.add_button('g2', 'Item 2')
win.add_button('g3', 'Item 3')
win.add_button('g4', 'Item 4')
win.add_button('g5', 'Item 5')
win.add_button('g6', 'Item 6')
win.end_grid()
```

### Tabbed Panel Container

```v
win.begin_tab_container('tab_view', ['General', 'Security', 'Advanced'])

// Tab 0: General
win.begin_tab_page('tab_gen', 0)
win.add_label('lbl_gen', 'General Settings Configuration')
win.end_tab_page()

// Tab 1: Security
win.begin_tab_page('tab_sec', 1)
win.add_label('lbl_sec', 'Security & Password Settings')
win.end_tab_page()

win.end_tab_container()
```

### Split Pane Layout

```v
// Left pane takes 30% width, right pane takes 70%
win.begin_split_view('split_pane', 30)
win.add_label('sidebar', 'Left Sidebar Navigation')
win.add_label('content', 'Main Right Content Area')
win.end_split_view()
```

### Framed Group Box / Card Box

```v
win.group('account_group', 'Account Details', fn (mut win simplegui.SimpleWindow) {
	win.add_form_field('Email Address:', 'user_email', 'user@example.com')
	win.add_form_password('New Password:', 'user_pass', '')
})
```

---

## 4. Control Customization & Fluent Styling

Every control can be styled using fluent method chaining on `&Control` or by calling `win.set_control_*('control_name', value)`.

### Fluent `&Control` Chaining Example

```v
mut btn := win.add_button('submit_btn', 'Submit Order')
btn.set_width(240)
	.set_height(45)
	.set_margin_xy(10, 5)
	.set_padding_xy(16, 10)
	.set_font_size(16)
	.set_font_bold(true)
	.set_corner_radius(8.0)
	.set_bg_color('#0a84ff')
	.set_font_color('#ffffff')
	.set_border(2.0, '#005bb5')
	.set_tooltip('Click to submit your order')
```

### Sizing & Geometry Methods

#### Set Width & Height

```v
win.set_control_width('submit_btn', 250)
win.set_control_height('submit_btn', 40)
win.set_control_size('submit_btn', 250, 40)
```

#### Get Control Width & Height

```v
w := win.get_control_width('submit_btn')
h := win.get_control_height('submit_btn')
```

#### Absolute Control Position

```v
win.set_control_position('submit_btn', 50, 120)
```

#### Alignment (`'left'`, `'center'`, `'right'`)

```v
win.set_control_alignment('submit_btn', 'center')
```

#### Expand & Fill Available Width

```v
win.set_control_expand_fill('submit_btn', true)
```

### Margins (Outer Spacing Around Widget)

```v
// Uniform margin on all 4 sides
win.set_control_margin('submit_btn', 12)

// Horizontal (mx) and Vertical (my) margins
win.set_control_margin_xy('submit_btn', 16, 8)

// Top, Right, Bottom, Left margins individually
win.set_control_margin_trbl('submit_btn', 10, 15, 10, 15)

// Read left margin
margin_val := win.get_control_margin('submit_btn')
```

### Padding (Inner Spacing Inside Widget)

```v
// Uniform inner padding
win.set_control_padding('submit_btn', 10)

// Horizontal (px) and Vertical (py) inner padding
win.set_control_padding_xy('submit_btn', 20, 10)

// Top, Right, Bottom, Left inner padding individually
win.set_control_padding_trbl('submit_btn', 8, 16, 8, 16)

// Read left padding
padding_val := win.get_control_padding('submit_btn')
```

### Typography & Fonts

```v
win.set_control_font_size('submit_btn', 18)
font_size := win.get_control_font_size('submit_btn')

win.set_control_font_bold('submit_btn', true)
win.set_control_font_name('submit_btn', 'Roboto')
win.set_control_text_align('submit_btn', 'center') // 'left', 'center', 'right'
```

### Color, Border & Appearance

```v
// Hex Background Color
win.set_control_bg_color('submit_btn', '#0a84ff')

// Hex Font Color
win.set_control_font_color('submit_btn', '#ffffff')

// Hex Accent Color
win.set_control_accent_color('submit_btn', '#34c759')

// Border Width & Hex Color
win.set_control_border('submit_btn', 2.0, '#005bb5')

// Corner Rounding Radius
win.set_control_corner_radius('submit_btn', 10.0)

// Opacity (0.0 to 1.0)
win.set_control_opacity('submit_btn', 0.85)

// Tooltip Text on Hover
win.set_control_tooltip('submit_btn', 'Click to confirm')
tip_text := win.get_control_tooltip('submit_btn')

// Visibility & Enabled state
win.set_control_visible('submit_btn', true)
win.set_control_enabled('submit_btn', true)
```

---

## 5. UI Widgets & Controls

Every widget is created with a unique `name` identifier. Below is a code block example for creating, reading, and updating every widget.

### Text Label & Section Heading

```v
// Static Text Label
win.add_label('lbl_title', 'Application Status: Ready')
win.set_text('lbl_title', 'Application Status: Running...')

// Heading with divider line
win.add_heading('User Information')

// Horizontal Divider with optional text
win.add_divider('Section Break')
```

### Push Button

```v
win.add_button('btn_action', 'Click Me')
win.on_click('btn_action', fn (mut win simplegui.SimpleWindow) {
	win.info('Clicked', 'Action button was clicked!')
})
```

### Text Input & Password Input

```v
// Single-line text input
win.add_input('txt_user', 'Initial Text')
username := win.get_text('txt_user')
win.set_text('txt_user', 'New Username')

// Password field (masked characters)
win.add_password('txt_pass', 'secret123')
pass := win.get_text('txt_pass')
```

### Multi-Line Textarea

```v
win.add_textarea('notes', 'Line 1\nLine 2\nLine 3')
content := win.get_text('notes')
win.set_text('notes', 'Updated multi-line content')
```

### Search Bar (With `🔍` icon and `✕` clear button)

```v
win.add_search_bar('search_input', 'Type to search...')
query := win.get_text('search_input')

win.on_enter('search_input', fn (mut win simplegui.SimpleWindow) {
	println("Searching for: ${win.get_text('search_input')}")
})
```

### Checkbox & Toggle Switch

```v
// Toggle Checkbox
win.add_checkbox('chk_opt', 'Enable Auto-Save', true)
is_checked := win.get_bool('chk_opt')
win.set_bool('chk_opt', false)

// Horizontal Toggle Switch
win.add_switch('sw_dark', 'Dark Mode', true)
is_switched := win.get_bool('sw_dark')
win.set_bool('sw_dark', false)
```

### Stepper Number Field (`▲` / `▼` Buttons)

```v
win.add_number('qty_input', 5)
qty := win.get_value_int('qty_input')
win.set_value_int('qty_input', 10)
```

### Range Slider (`0`–`100`)

```v
win.add_slider('vol_slider', 75)
volume := win.get_value_int('vol_slider')
win.set_value_int('vol_slider', 90)
```

### Popup Dropdown Selector

```v
win.add_dropdown('role_select', ['Admin', 'Developer', 'Designer'], 'Developer')
selected_role := win.get_text('role_select')
win.set_text('role_select', 'Admin')
```

### Segmented Choice Control (Pill Selector)

```v
win.add_segmented_control('view_mode', ['Grid', 'List', 'Map'], 'Grid')
active_mode := win.get_text('view_mode')
win.set_text('view_mode', 'List')
```

### Interactive Data Table

```v
headers := ['ID', 'Name', 'Role', 'Status']
rows := [
	['101', 'Ada Lovelace', 'Engineer', 'Active'],
	['102', 'Alan Turing', 'Scientist', 'Active'],
	['103', 'Grace Hopper', 'Pioneer', 'Offline'],
]

win.add_table('user_table', headers, rows)

// Handle row selection
win.on_row_click('user_table', fn (mut win simplegui.SimpleWindow) {
	selected_row := win.get_table_selected_row('user_table')
	println("Selected table row #${selected_row}")
})
```

### Expandable Tree View Control

```v
tree_data := [
	simplegui.TreeNode{
		label: 'Documents'
		children: [
			simplegui.TreeNode{ label: 'Project.v' },
			simplegui.TreeNode{ label: 'README.md' },
		]
	},
	simplegui.TreeNode{
		label: 'Downloads'
		children: [
			simplegui.TreeNode{ label: 'archive.zip' },
		]
	},
]

win.add_tree_view('file_tree', tree_data)
```

### File Picker Input (Input Field + "Browse..." Button)

```v
win.add_file_picker('picker', 'Select File:', '/home/user/document.pdf')
selected_file := win.get_text('picker')
win.set_text('picker', '/home/user/new_doc.pdf')
```

### Status Badge Pill (`'success'`, `'warning'`, `'danger'`, `'info'`)

```v
win.add_badge('status_badge', 'System Online', 'success')
win.set_text('status_badge', 'Warning High Load')
```

### Breadcrumb Navigation Path

```v
win.add_breadcrumb('nav_path', ['Home', 'Projects', 'SimpleGUI', 'Settings'])
```

### Step Wizard Indicator

```v
steps := ['Account', 'Payment', 'Confirmation']
win.add_stepper('wizard_step', steps, 1) // 0-indexed active step (1 = Payment)
win.set_value_int('wizard_step', 2)
```

### Accordion Card (Collapsible Box)

```v
win.add_accordion('acc1', 'Advanced Settings', 'Contains advanced user configurations and API keys.', false)
```

### User Avatar Display

```v
win.add_avatar('user_avatar', 'AL', 'Ada Lovelace')
```

### Interactive 5-Star Rating (`★★★★☆`)

```v
win.add_rating('star_rating', 4)
stars := win.get_value_int('star_rating') // returns 4
win.set_value_int('star_rating', 5)
```

### Date Picker Field (`📅`)

```v
win.add_date_picker('birthday', '2026-08-11')
date_str := win.get_text('birthday')
win.set_text('birthday', '2026-12-25')
```

### Color Well Swatch

```v
win.add_color_well('color_swatch', '#0a84ff')
color_hex := win.get_text('color_swatch')
win.set_text('color_swatch', '#ff3b30')
```

### Progress Indicator Bar (`0`–`100`)

```v
win.add_progress_indicator('download_progress', 45)
pct := win.get_value_int('download_progress')
win.set_value_int('download_progress', 80)
```

### Metric KPI Card

```v
win.add_metric_card('kpi_revenue', 'Monthly Revenue', '$45,230', '+12.4%', 'vs last month')
```

### Trend Polyline Chart

```v
win.add_chart('sales_chart', 'line', 150) // chart height: 150px
```

---

## 6. Form Field Helpers

Form field helpers automatically add a label and widget together in one unified call:

```v
// 1. Text Field
win.add_form_field('Full Name:', 'form_name', 'Jane Doe')

// 2. Password Field
win.add_form_password('Password:', 'form_pass', 'secret')

// 3. Search Field
win.add_form_search('Search Catalog:', 'form_search', 'Keyword...')

// 4. File Picker Field
win.add_form_file_picker('Upload CSV:', 'form_file', '/tmp/data.csv')

// 5. Color Picker
win.add_form_color_picker('Theme Accent:', 'form_color', '#0a84ff')

// 6. Rating Stars
win.add_form_rating('App Score:', 'form_rate', 5)

// 7. Dropdown Selector
win.add_form_dropdown('Country:', 'form_country', ['USA', 'Canada', 'UK'], 'USA')

// 8. Number Stepper
win.add_form_number('Quantity:', 'form_qty', 1)

// 9. Range Slider
win.add_form_slider('Brightness:', 'form_bright', 80)

// 10. Switch Toggle
win.add_form_switch('Notifications:', 'form_notify', 'Send Email Digest', true)

// 11. Date Picker
win.add_form_date_picker('Event Date:', 'form_date', '2026-09-01')

// 12. Progress Bar
win.add_form_progress('Sync Status:', 'form_sync', 60)
```

---

## 7. Nameless Control Shortcuts

For quick scripts and one-off dialogs, create controls without string IDs:

```v
// Input Shortcut
win.input('Default Value')
user_val := win.get_input()

// Checkbox Shortcut
win.checkbox('Enable feature', true)
chk_val := win.get_checkbox()

// Number Stepper Shortcut
win.number(42)
num_val := win.get_number()

// Button Shortcut
win.button('Submit Quick Form')
```

---

## 8. Reading & Writing Values

### String Values

```v
// Read string value from input, password, textarea, dropdown, search, or date picker
str_val := win.get_text('my_control')

// Update string value
win.set_text('my_control', 'Updated Text')
```

### Boolean Values

```v
// Read checked state from checkbox or switch
bool_val := win.get_bool('chk_notify')

// Update boolean state
win.set_bool('chk_notify', true)
```

### Integer Values

```v
// Read numeric integer from number stepper, slider, progress bar, rating, or tab index
int_val := win.get_value_int('qty_input')

// Update integer value
win.set_value_int('qty_input', 25)
```

### Typed Ergonomic Accessors (`get_int`, `get_f64`, `set_int`, `set_f64`)

```v
// Parse integer from text or number field safely
count := win.get_int('txt_count')
win.set_int('txt_count', 100)

// Parse float from text or slider field safely
price := win.get_f64('txt_price')
win.set_f64('txt_price', 49.99)
```

### Table Selected Row

```v
// Returns selected row index (0-indexed, -1 if no row selected)
row_idx := win.get_table_selected_row('my_table')
```

### Batch Reading & Writing Control Values

```v
// Read multiple control values into a map
values_map := win.get_all(['username', 'email', 'country'])
println(values_map['username'])

// Set multiple control values at once from a map
win.set_all({
	'username': 'ada_lovelace',
	'email': 'ada@vlang.io'
})

// Clear text of multiple controls
win.clear_all(['username', 'email', 'country'])
```

---

## 9. Event Handling & Callbacks

### Button Click Listener (`on_click`)

```v
win.add_button('btn_save', 'Save Changes')
win.on_click('btn_save', fn (mut win simplegui.SimpleWindow) {
	win.info('Saved', 'Your changes have been saved.')
})
```

### Value Change Listener (`on_change`)

Triggers whenever text is typed, a checkbox is clicked, a slider is dragged, or a dropdown option is picked:

```v
win.add_dropdown('theme_picker', ['Apple Light', 'Apple Dark', 'Nord'], 'Apple Dark')
win.on_change('theme_picker', fn (mut win simplegui.SimpleWindow) {
	new_theme := win.get_text('theme_picker')
	win.set_theme(new_theme)
})
```

### Enter Key Listener (`on_enter`)

Triggers when the user hits `Enter` inside an input or search bar:

```v
win.add_input('search_field', '')
win.on_enter('search_field', fn (mut win simplegui.SimpleWindow) {
	q := win.get_text('search_field')
	println("User pressed Enter to search: ${q}")
})
```

### Table Row Click Listener (`on_row_click`)

```v
win.on_row_click('user_table', fn (mut win simplegui.SimpleWindow) {
	idx := win.get_table_selected_row('user_table')
	println("Clicked row index: ${idx}")
})
```

### Window Close Interceptor (`on_close`)

Intercepts `Cmd+Q`, `Ctrl+Q`, or closing the window:

```v
win.on_close(fn (mut win simplegui.SimpleWindow) bool {
	confirmed := win.ask('Confirm Exit', 'Are you sure you want to quit?')
	return confirmed // return true to close, false to cancel
})
```

### Form Submit Event (`on_submit`)

```v
win.on_submit(fn (mut win simplegui.SimpleWindow) {
	println("Form submission event triggered!")
})
```

### Global Keyboard Key Listener (`on_key_down`)

```v
win.on_key_down(fn (mut win simplegui.SimpleWindow, key gg.KeyCode) {
	if key == .escape {
		println("Escape key pressed!")
	}
})
```

### Window Resize Event (`on_window_resize`)

```v
win.on_window_resize(fn (mut win simplegui.SimpleWindow, w int, h int) {
	println("Window resized to: ${w}x${h}")
})
```

---

## 10. RAD Development & System Utilities

### Dialogs & Toast Notifications

```v
// Information Toast Alert
win.info('Notice', 'File uploaded successfully.')

// Warning Toast Alert
win.warn('Low Disk Space', 'Storage is 90% full.')

// Error Toast Alert
win.error_dialog('Connection Failed', 'Could not reach server.')

// System Confirmation Popup (returns true/false)
if win.ask('Delete File', 'Do you really want to delete this file?') {
	println("User confirmed deletion.")
}
```

### Batch Visibility & State Toggles

```v
// Show or Hide multiple controls
win.show_controls(['btn_save', 'btn_cancel'])
win.hide_controls(['lbl_loading', 'progress_bar'])

// Enable or Disable multiple controls
win.enable_controls(['txt_user', 'txt_pass'])
win.disable_controls(['btn_submit'])

// Enable or Disable ALL controls in window
win.enable_all()
win.disable_all()

// Toggle single control state
win.toggle_visible('my_panel') // returns new visibility boolean
win.toggle_enabled('submit_btn') // returns new enabled boolean
```

### Form JSON Serialization & Import

```v
// Export form values into JSON string
json_str := win.export_form_json(['username', 'email', 'notify'])
println(json_str)

// Import and populate form from JSON string
win.import_form_json('{"username":"ada","email":"ada@vlang.io","notify":"true"}')
```

### System Clipboard

```v
// Copy text to system clipboard
win.copy_to_clipboard('Hello from SimpleGUI!')

// Read text from system clipboard
clip_text := win.get_clipboard_text()
```

### Native Desktop Notifications & File Manager

```v
// Trigger OS desktop banner notification (macOS notification center / Windows toast / Linux notify-send)
win.show_system_notification('Background Job', 'Backup completed in 4.2 seconds.')

// Open URL or file path in system default browser / viewer
win.open_url('https://vlang.io')

// Open file/folder in macOS Finder / Windows Explorer / Linux File Manager
win.reveal_in_finder('/path/to/my/folder')
```

### Resolve Standard OS System Directories

```v
home_dir := win.get_system_path('home')       // e.g. /Users/username
desktop := win.get_system_path('desktop')     // e.g. /Users/username/Desktop
docs := win.get_system_path('documents')      // e.g. /Users/username/Documents
downloads := win.get_system_path('downloads') // e.g. /Users/username/Downloads
tmp_dir := win.get_system_path('tmp')         // e.g. /tmp
app_dir := win.get_system_path('app')         // current working directory
config_dir := win.get_system_path('config')   // app config directory
```

### Execute Shell Commands

```v
// Synchronously execute shell command (returns stdout string and exit code int)
stdout, exit_code := win.exec('ls -la')

// Execute shell command with fallback string on non-zero exit code
result := win.exec_or('which git', 'git not found')

// Asynchronously execute shell command in background
win.exec_bg('ping -c 5 google.com')
```

### Environment Variables

```v
// Read process environment variable
path_env := win.get_env('PATH')

// Set process environment variable
win.set_env('MY_APP_ENV', 'production')
```

---

## 11. More Developer & User-Requested Controls

### Icon Button & Toolbar

```v
// Single square icon button
win.add_icon_button('btn_new', '[New]', 'Create a new document')
win.on_click('btn_new', fn (mut win simplegui.SimpleWindow) {
	win.show_toast('Toolbar', 'New document created')
})

// Row of icon buttons with tooltips and callbacks
win.add_toolbar('main_toolbar', [
	simplegui.ToolbarItem{
		icon: '[New]'
		tooltip: 'Create a new document'
		on_click: fn (mut win simplegui.SimpleWindow) {
			win.show_toast('Toolbar', 'New document created')
		}
	},
	simplegui.ToolbarItem{
		icon: '[Save]'
		tooltip: 'Save the current document'
		on_click: fn (mut win simplegui.SimpleWindow) {
			win.show_toast('Toolbar', 'Document saved')
		}
	},
])
```

### Hyperlink

```v
// Clickable text that opens a URL in the system default browser
win.add_link('docs_link', 'Open SimpleGUI Documentation', 'https://vlang.io')
```

### Dropdown Menu Button

```v
// Click to expand a list of action items below the button
win.add_menu_button('file_menu', 'Actions', ['Export CSV', 'Export JSON', 'Print', 'Archive'])

win.on_change('file_menu', fn (mut win simplegui.SimpleWindow) {
	selected := win.get_menu_selected('file_menu')
	win.show_toast('Menu Action', 'You picked: ${selected}')
})
```

### Multi-Select Checklist

```v
win.add_checklist('perms_checklist', ['Read', 'Write', 'Execute', 'Delete', 'Share'], ['Read', 'Write'])

win.on_change('perms_checklist', fn (mut win simplegui.SimpleWindow) {
	selected := win.get_checklist_selected('perms_checklist')
	println('Checklist selection: ${selected}')
})

// Programmatically update selection
win.set_checklist_selected('perms_checklist', ['Read'])
```

### Chip Group (Multi-Select Tag Selector)

```v
win.add_chip_group('tags_chip_group', ['Urgent', 'Bug', 'Feature', 'Design', 'Backend'], ['Bug'])

win.on_change('tags_chip_group', fn (mut win simplegui.SimpleWindow) {
	selected := win.get_chip_selected('tags_chip_group')
	println('Chip selection: ${selected}')
})

// Programmatically update selection
win.set_chip_selected('tags_chip_group', ['Bug', 'Urgent'])
```

### Time Picker

```v
win.add_time_picker('meeting_time', '09:30')
time_str := win.get_text('meeting_time')

// Or with an auto-generated label row
win.add_form_time_picker('Meeting Time:', 'meeting_time', '09:30')
```

### Password Strength Meter

```v
// Add a password field, then link a strength meter to it by control name
win.add_form_password('New Password:', 'new_password', '')
win.add_password_strength('pwd_strength_meter', 'new_password')
```
