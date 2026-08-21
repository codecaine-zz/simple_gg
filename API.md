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
19. [Cross-Window Spy++ & External App Automation](#19-cross-window-spy--external-app-automation)
20. [Modern Super Controls (Developer Heaven Catalog)](#20-modern-super-controls-developer-heaven-catalog)
21. [Modern Image Super Controls & Developer Asset Catalog](#21-modern-image-super-controls--developer-asset-catalog)
22. [Type & Struct Reference Index](#22-type--struct-reference-index)


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

### Window Title & Subtitle

```v
// Read or modify window title bar string
win.set_title('Dashboard Manager v2.0')
win.set_window_title('Dashboard Manager v2.0') // Alias syntax
title_str := win.get_title()

// Set secondary subtitle header
win.set_subtitle('System Administrator Workspace')
sub_str := win.get_subtitle()
```

### Control Inspection & Direct Pointer Access

Lookup, verify, or retrieve pointer references to controls registered in the window:

```v
// Check if control name exists in window registry
if win.has_control('input_email') {
    println('Control registered!')
}

// List names of all controls registered in the window ([]string)
all_names := win.list_controls()

// Get kind identifier string (e.g. 'button', 'input', 'table')
kind := win.get_control_kind('btn_save')

// Panics with helpful error message if control is missing
win.require_control('btn_save')

// Retrieve mutable reference pointer !&Control (returns error if missing)
mut ctrl_ptr := win.get_control_ptr('btn_save') or { return }

// Retrieve mutable reference pointer &Control directly (panics if missing)
mut ctrl := win.control('btn_save')
```

### Window Dimensions, Bounds & Geometry

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

// Set bounds (x, y, width, height)
win.set_bounds(0, 0, 1024, 768)
x, y, bw, bh := win.get_bounds()

// Read window position coordinates
pos_x := win.get_x()
pos_y := win.get_y()
px, py := win.get_position()
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
win.set_minimum_size(400, 300) // Alias syntax
win.set_max_size(1920, 1080)
win.set_maximum_size(1920, 1080) // Alias syntax
min_w, min_h := win.get_min_size() // or win.get_minimum_size()
max_w, max_h := win.get_max_size() // or win.get_maximum_size()

// Window Opacity & Alpha
win.set_opacity(0.95)
win.set_alpha(0.95) // Alias for set_opacity

// Custom Cursor Scaling
win.set_cursor_size(1.5)
cur_sz := win.get_cursor_size()

// Debug Mode Toggle & Status
win.set_debug_mode(true)
is_debug := win.get_debug_mode()

// Register Custom Control Pointer Directly
win.add_control(my_control)

// Close Keyboard Shortcut Toggle
win.set_close_shortcut_enabled(true)

// Preset sizes: 'small' (400x300), 'medium' (640x480), 'large' (800x600),
// 'xlarge' (1024x768), 'hd' (1280x720), 'full_hd' (1920x1080), 'dialog' (420x220), 'settings' (550x400)
win.set_size_preset('hd')
// Alias: win.set_preset_size('hd')
```

### Window Options & Platform Flags

```v
// Resizable flag
win.set_resizable(true)
is_resizable := win.get_resizable()

// Minimizable flag
win.set_minimizable(true)
is_minimizable := win.get_minimizable()

// Maximizable flag
win.set_maximizable(true)
is_maximizable := win.get_maximizable()

// Closable flag
win.set_closable(true)
is_closable := win.get_closable()

// Titlebar & Title Text Visibility
win.set_titlebar_visible(true)
is_tb_vis := win.is_titlebar_visible()
win.set_title_visible(true)
is_t_vis := win.is_title_visible() // or win.get_title_visible()

// Window Drop Shadow
win.set_has_shadow(true)
has_shadow := win.get_has_shadow()
```

### Full Screen & Window State Inspection

```v
win.set_fullscreen(true)     // Enable full screen window
win.toggle_fullscreen()      // Toggle full screen state
is_fs := win.is_fullscreen() // Returns true if currently full screen

// Inspect active window states
is_vis := win.is_visible()
is_act := win.is_active()
is_min := win.is_minimized()
is_max := win.is_maximized()
```

### RAD Preset Window Types & Builder Helpers

```v
// Create a centered non-resizable dialog window
mut dialog := simplegui.new_simple_window('Dialog', 420, 220).make_fixed_dialog('Confirm Action', 420, 220)

// Create a borderless splash screen window
mut splash := simplegui.new_simple_window('Splash', 500, 300).make_splash_screen(500, 300)

// Create a slim floating utility panel
mut panel := simplegui.new_simple_window('Panel', 300, 600).make_utility_panel()

// Additional builder helpers
win.make_frameless()
win.make_always_on_top(true)
win.make_modal()
win.make_translucent(0.9)
```

### Positioning, Alignment, Dock & Animations

```v
// Center window on screen
win.center_window()
// Aliases: win.center(), win.recenter(), win.center_on_screen(), win.center_and_focus()

// Align window on screen: 'top_left', 'top_right', 'bottom_left', 'bottom_right', 'center'
win.align_window('top_right')
// Alias: win.align('top_right')

// Shake window animations (e.g. invalid login feedback)
win.shake_window()
win.shake_on_error()
win.flash_and_shake()

// Set opacity (0.0 to 1.0)
win.set_opacity(0.95)
op := win.get_opacity() // or win.get_alpha()

// Make window movable by clicking anywhere on background
win.set_movable_by_window_background(true)
is_movable := win.get_movable_by_window_background()

// Keep window stayed on top of other desktop windows
win.set_always_on_top(true) // or win.set_topmost(true)
is_top := win.get_always_on_top() // or win.is_topmost()

// Dock & Attention requests
win.attention()
win.request_attention(true)
win.bounce_dock(true)
win.bounce_dock_icon(true)
```

### Mouse Cursor & Pointer Position API

```v
// Change mouse cursor icon ('arrow', 'hand', 'ibeam', 'pointer', 'crosshair')
win.set_cursor('hand')
cur := win.get_cursor()
win.reset_cursor()

// Push and pop temporary cursor stack states
win.push_cursor('ibeam')
win.pop_cursor()

// Set custom cursor specifically for a target control
win.set_control_cursor('btn_submit', 'pointer')

// Query live mouse cursor screen location (x, y)
mx, my := win.get_mouse_location()

// Programmatically warp/move mouse cursor coordinates
win.move_cursor_to(100, 200)
```

### Window Lifecycle & Actions

```v
// Start window loop (blocks thread until window closes)
win.run()

// Programmatically minimize, maximize or restore window
win.minimize()
win.deminimize()
win.maximize()
win.zoom()
win.restore()
win.restore_window()

// Programmatically close or hide window
win.close()
win.close_window()
win.hide()
win.hide_window()
win.show()
```

---

## 3. Built-in Themes & Styling

`simplegui` includes 34 curated light and dark themes across macOS, Futuristic/Sci-Fi, Business/Corporate, and Developer categories with interactive hover palettes (`hover_color` and `surface_hover`). Setting a theme instantly updates all controls, fonts, hover states, cards, and background colors.

```v
// Apply theme by name
win.set_theme('Synthwave 84')

// Toggle between Apple Light and Apple Dark themes
win.toggle_window_theme()
win.set_dark_theme(true)
is_dark := win.is_dark_theme()

// Apply Theme struct directly
custom_t := simplegui.Theme{
    name: 'Custom Theme'
    background_color: '#0f172a'
    font_color: '#f8fafc'
    accent_color: '#3b82f6'
    hover_color: '#60a5fa'
    surface_hover: '#1e293b'
    is_dark: true
}
win.apply_theme(custom_t)

// Set custom window background or font color overrides
win.set_background_color('#1e1e2e')
win.set_font_color('#f5c2e7')

// Parse CSS hex color string to V `gg.Color` (RGB byte values)
color := simplegui.parse_hex_color('#0a84ff') // or shorthand '#07f'

// List all available theme names (34 built-in themes)
themes := simplegui.list_themes()

// Get Theme struct by alias
theme := simplegui.get_theme('executive') // Accepts 'dark', 'nord', 'synthwave', 'corporate', 'matrix', etc.
// Theme fields include: theme.background_color, theme.font_color, theme.accent_color, theme.hover_color, theme.surface_hover
```

### Themes Reference Table

| Theme Name              | Style Description                       | Background | Accent Color | Hover Color | Type  |
| :---------------------- | :-------------------------------------- | :--------- | :----------- | :---------- | :---- |
| **`Apple Light`**       | Default clean macOS light mode          | `#ffffff`  | `#007aff`    | `#3395ff`   | Light |
| **`Apple Dark`**        | Modern macOS dark mode                  | `#1c1c1e`  | `#0a84ff`    | `#409cff`   | Dark  |
| **`Synthwave 84`**      | Retro 80s synthwave neon twilight       | `#261535`  | `#ff7edb`    | `#36f9f6`   | Dark  |
| **`Neon Matrix`**       | Digital phosphor green cyber terminal   | `#05100a`  | `#39ff14`    | `#00ffaa`   | Dark  |
| **`Holodeck Cyan`**     | Futuristic glowing holographic cyan     | `#050b14`  | `#00f0ff`    | `#70f3ff`   | Dark  |
| **`Sci-Fi HUD Orange`** | Tactical amber cockpit HUD              | `#121316`  | `#ff6600`    | `#ffcc00`   | Dark  |
| **`Quantum Violet`**    | Quantum glow electric purple dark       | `#110926`  | `#9d4edd`    | `#c77dff`   | Dark  |
| **`Corporate Navy`**    | Enterprise corporate navy light mode    | `#f8fafc`  | `#1e40af`    | `#2563eb`   | Light |
| **`Executive Slate`**   | Dark executive slate dashboard          | `#1e293b`  | `#3b82f6`    | `#60a5fa`   | Dark  |
| **`Financial Gold`**    | Fintech luxury gold & dark bronze       | `#181614`  | `#d97706`    | `#f59e0b`   | Dark  |
| **`Enterprise Light`**  | Clean modern SaaS admin panel           | `#f3f4f6`  | `#0d9488`    | `#14b8a6`   | Light |
| **`Modern Minimalist`** | Stark high-contrast monochrome          | `#ffffff`  | `#18181b`    | `#3f3f46`   | Light |
| **`Pro Charcoal`**      | Sleek pro charcoal SaaS dark mode       | `#18181b`  | `#6366f1`    | `#818cf8`   | Dark  |
| **`Tokyo Night`**       | Iconic Tokyo neon night IDE theme       | `#1a1b26`  | `#7aa2f7`    | `#bb9af7`   | Dark  |
| **`One Dark Pro`**      | Atom One Dark editor palette            | `#282c34`  | `#61afef`    | `#c678dd`   | Dark  |
| **`Gruvbox Dark`**      | Retro warm orange/green developer theme | `#282828`  | `#fabd2f`    | `#fe8019`   | Dark  |
| **`Monokai Pro`**       | Classic Monokai vivid dark palette      | `#2d2a2e`  | `#ff6188`    | `#ffd866`   | Dark  |
| **`Rosé Pine`**         | Natural rose gold & purple theme        | `#191724`  | `#ebbcba`    | `#c4a7e7`   | Dark  |
| **`Coffee Roast`**      | Warm cozy espresso dark mode            | `#1c1613`  | `#d97706`    | `#f59e0b`   | Dark  |
| **`Nord`**              | Cool arctic frost blue palette          | `#2e3440`  | `#88c0d0`    | `#81a1c1`   | Dark  |
| **`Dracula`**           | Classic vampire dark purple             | `#282a36`  | `#bd93f9`    | `#ff79c6`   | Dark  |
| **`Cyberpunk`**         | High-contrast neon dark vibe            | `#0d0d15`  | `#ff007f`    | `#7000ff`   | Dark  |
| **`Catppuccin Mocha`**  | Smooth pastel dark theme                | `#1e1e2e`  | `#cba6f7`    | `#f5c2e7`   | Dark  |
| **`GitHub Dark`**       | Official GitHub dark mode               | `#0d1117`  | `#58a6ff`    | `#79c0ff`   | Dark  |
| **`GitHub Light`**      | Official GitHub light mode              | `#ffffff`  | `#0969da`    | `#218bff`   | Light |
| **`Sonoma Emerald`**    | Dark forest glass layout                | `#0d1f18`  | `#30d158`    | `#4ade80`   | Dark  |
| **`Ventura Amber`**     | Warm sunset dark palette                | `#211815`  | `#ff9500`    | `#ffaa33`   | Dark  |

---

## 4. Layout Containers & Grouping

Organize controls easily using rows, grids, flexboxes, tabbed panels, split views, and group cards.

### 1. Horizontal Row (`begin_row` / `end_row` / `row`)

Arranges controls horizontally side-by-side:

```v
win.begin_row('btn_row')
win.add_button('btn_ok', 'OK')
win.add_button('btn_cancel', 'Cancel')
win.add_button('btn_help', 'Help')
win.end_row()

// Closure-based row helper:
win.row('action_row', fn (mut win simplegui.SimpleWindow) {
    win.add_button('btn_save', 'Save')
    win.add_button('btn_delete', 'Delete')
})
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

### 4. Tabbed Container (`begin_tab_container` / `end_tab_container` / `add_tabs`)

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

// Quick tab header addition helper:
win.add_tabs('quick_tabs', ['Tab 1', 'Tab 2', 'Tab 3'])
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

### 6. Group Box Card (`group` / `begin_group` / `add_group_box`)

Wraps widgets in a visual card container with a header title:

```v
win.group('grp_account', 'User Credentials', fn (mut win simplegui.SimpleWindow) {
	win.add_form_field('Username:', 'input_u', 'admin')
	win.add_form_password('Password:', 'input_p', 'secret123')
})

// Direct group box container additions:
win.begin_group('Settings')
// ... add controls ...
win.end_group()

// Alternative group box helpers:
win.add_group_box('grp_options', 'Preferences')
win.add_group_box_with_options('grp_framed', 'Advanced Settings', true)
win.group_with_options('grp_opt', 'Group Title', true, fn (mut win simplegui.SimpleWindow) {})
win.group_config('grp_cfg', simplegui.GroupConfig{ title: 'Config' }, fn (mut win simplegui.SimpleWindow) {})
win.card_with_title('card_t', 'Card Header', fn (mut win simplegui.SimpleWindow) {})

// Header & Alignment Helpers
win.add_header('Page Title')
win.align_left()
win.align_center()
win.align_right()

// Internal Layout & Rendering Pipeline Calls
win.recalculate_layout()
win.render_ui()
win.handle_event(e)
```

### 7. Scroll View & Quick Action Rows

```v
// Scroll View container (height in pixels)
win.add_scroll_view('scroll_panel', 300)

// Quick action row dictionary helper (button title -> click callback)
win.add_action_row({
    'Save': fn (mut win simplegui.SimpleWindow) { win.toast('Saved!') }
    'Cancel': fn (mut win simplegui.SimpleWindow) { win.toast('Cancelled!') }
})

// Quick fields row dictionary helper (field name -> initial text)
win.add_fields_row({
    'First Name': 'Ada'
    'Last Name': 'Lovelace'
})
```

### 8. Layout Padding, Spacing & Responsive Engine

```v
// Set window outer edge padding (pixels)
win.set_padding(16)
p := win.get_padding()

// Set default vertical gap spacing between controls (pixels)
win.set_spacing(10)
s := win.get_spacing()

// Enable or disable automatic responsive recalculations on window resize
win.set_responsive_layout(true)
is_resp := win.get_responsive_layout()
```

### 9. Spacers & Separators

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

### Buttons & Actions

```v
win.add_button('btn_run', '[Run] Start Processing')

// Add action button with inline click callback
win.add_action('btn_exec', 'Execute Task', fn (mut win simplegui.SimpleWindow) {
	win.info('Executed', 'Task started')
})

// Add icon button (icon symbol + hover tooltip)
win.add_icon_button('btn_refresh', '[R]', 'Refresh Dataset')

win.on_click('btn_run', fn (mut win simplegui.SimpleWindow) {
	win.info('Started', 'Processing job launched!')
})
```

### Inputs, Passwords & Textareas

```v
win.add_input('input_host', 'localhost')
win.add_password('input_secret', 'my_pass_123')
win.add_textarea('input_logs', 'Line 1: Started\nLine 2: Ready')
win.add_search_field('sf_query', 'Filter results...')
```

#### ✂️ Text Selection & Clipboard Shortcuts

All text input controls (`input`, `password`, `textarea`, `search_field`, `search_bar`, `file_picker`, `number`, `code_editor`) support multi-character text selection and full system clipboard interaction out of the box:

- **Mouse Selection**: Click and drag across text to select a range of characters. Shift-click extends selection from cursor. Double-clicking selects all text.
- **Select All (`Ctrl+A` / `Cmd+A`)**: Selects all text inside the focused input field.
- **Copy (`Ctrl+C` / `Cmd+C`)**: Copies the active text selection to the system clipboard.
- **Cut (`Ctrl+X` / `Cmd+X`)**: Copies the active text selection to the system clipboard and deletes it from the field.
- **Paste (`Ctrl+V` / `Cmd+V`)**: Pastes text from the system clipboard at current caret position (or replaces active selection).
- **Undo (`Ctrl+Z` / `Cmd+Z`)**: Reverts the last text editing change from history stack.
- **Shift Navigation**: `Shift + Left / Right / Home / End` expands or contracts text selection.
- **Character Replacement**: Typing printable characters or pressing `Backspace`/`Delete` while text is selected replaces or removes the selected range cleanly.

#### 🛠️ Programmatic Text Selection API

Programmatically inspect or manipulate text selection on `Control` pointers:

```v
if mut ctrl := win.get_control_ptr('input_host') {
    ctrl.select_all()                  // Select all text in control
    has_sel := ctrl.has_selection()    // Returns true if text selection is active
    sel_txt := ctrl.selected_text()    // Returns substring of currently selected text
    ctrl.delete_selected_text()        // Deletes selected range and resets caret
    ctrl.clear_selection()             // Clears selection highlight
    ctrl.undo()                        // Reverts last text mutation from history stack
}
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
win.add_radio_group('radio_plan', ['Free', 'Pro', 'Enterprise'], 'Pro')
```

### Steppers & Sliders

```v
win.add_number('num_count', 5)             // Up/Down integer stepper
win.add_number_field('num_field', 10)      // Alias for add_number
win.add_slider('slider_vol', 75)           // Range slider 0 to 100
win.add_progress_bar('prog_bar', 65)       // Progress bar indicator
win.add_progress_indicator('prog_ind', 40) // Progress indicator
win.add_rating('star_rating', 4)           // 5-star rating control
```

### Dropdowns, Segmented & Mode Controls

```v
win.add_dropdown('drop_role', ['Administrator', 'Developer', 'Guest'], 'Developer')
win.add_segmented_control('seg_view', ['Grid View', 'List View', 'Map'], 'Grid View')
win.add_mode_control('mode_select', 'Grid View')
```

### Data Table & Data Grid

Supports header sorting, row selection, row addition/removal, scrolling, and dynamic dataset updating:

```v
headers := ['ID', 'Full Name', 'Role', 'Status']
rows := [
	['1', 'Ada Lovelace', 'Mathematician', 'Active'],
	['2', 'Alan Turing', 'Cryptanalyst', 'Active'],
	['3', 'Grace Hopper', 'Computer Scientist', 'Offline'],
]

win.add_table('tbl_users', headers, rows)
win.set_control_height('tbl_users', 200)

// Data Grid (interactive table layout)
win.add_grid('grid_users', headers, rows)

// Append single row to table
win.add_table_row('tbl_users', ['4', 'John von Neumann', 'Polymath', 'Active'])

// Remove row at zero-based index
win.remove_table_row('tbl_users', 2)

// Programmatic sorting (Column 1 ascending)
win.sort_table('tbl_users', 1, true)
col_idx, is_asc := win.get_table_sort('tbl_users') // Read active sort column index and direction

// Row selection event
win.on_row_click('tbl_users', fn (mut win simplegui.SimpleWindow) {
	idx := win.get_table_selected_row('tbl_users')
	println('Selected row index: ${idx}')
})

// Update dataset dynamically
win.set_table_data('tbl_users', headers, new_rows)
win.set_table_rows('tbl_users', new_rows)
table_rows := win.get_table_rows('tbl_users')
win.clear_table_selection('tbl_users')
```

### Charts & KPI Cards

```v
// Line Chart
win.add_line_chart('chart_sales', 'Monthly Revenue ($k)', [12.5, 18.2, 24.0, 31.8, 42.0])

// Bar Chart
win.add_bar_chart('chart_visitors', 'Daily Visitors', ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'], [120.0, 240.0, 180.0, 310.0, 450.0])

// Generic Chart container (chart_type: 'line', 'bar', etc.)
win.add_chart('chart_generic', 'line', 200)
win.set_chart_data('chart_sales', [10.0, 20.0, 30.0, 40.0])

// Metric KPI Card
win.add_metric_card('kpi_sales', 'Total Revenue', '$48,250', '+14.2%', 'vs last month')
```

### Lists, ListBox & Multi-Select

```v
// Standard ListBox
win.add_list_box('list_items', ['Item A', 'Item B', 'Item C'])

// Single-Select ListBox with initial selection
win.add_list_box_with_selected('list_files', ['file1.txt', 'file2.csv', 'document.pdf'], 'file1.txt')
selected_file := win.get_list_box_selected('list_files')
selected_idx := win.get_list_box_index('list_files')
win.set_list_box_selected('list_files', 'file2.csv')
win.set_list_box_index('list_files', 1)

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
win.add_breadcrumb('nav_crumb', ['Home', 'Dashboard']) // Alias for add_breadcrumbs
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

// Open native OS platform file picker dialog directly
picked_path := simplegui.open_native_file_dialog()
```

### Media, Canvas & Links

```v
win.add_image('img_logo', '/path/to/logo.png')
win.add_image_view('img_preview', 'Preview Image', 300, 200)
win.add_canvas('canvas_draw', 400, 200)
win.add_spinner('loading_spinner', true)
win.add_link('link_docs', 'Open Official V Language Documentation', 'https://vlang.io')
```

### Tags & Utility Controls

```v
win.add_tag_cloud('tags_cloud', ['Vlang', 'GUI', 'Desktop', 'CrossPlatform'])

// Interactive Chip Group
win.add_chip_group('chips_tags', ['Bug', 'Feature', 'Documentation'], ['Bug'])
chips := win.get_chip_selected('chips_tags')
win.set_chip_selected('chips_tags', ['Bug', 'Feature'])

win.add_rich_text('rich_desc', '**Bold** and *italic* text formatting supported.')
win.add_keyboard_shortcut('hk_save', 'Ctrl+S', 'Save Project')
win.add_toolbar('main_tb', [
	simplegui.ToolbarItem{ icon: '[New]', tooltip: 'New File', on_click: fn (mut win simplegui.SimpleWindow) {} },
	simplegui.ToolbarItem{ icon: '[Save]', tooltip: 'Save File', on_click: fn (mut win simplegui.SimpleWindow) {} }
])

// Menu Button
win.add_menu_button('menu_actions', 'Actions v', ['Export PDF', 'Export CSV', 'Print'])
chosen_menu := win.get_menu_selected('menu_actions')

// Checklist
win.add_checklist('chk_perms', ['Read', 'Write', 'Execute'], ['Read'])
chk_items := win.get_checklist_selected('chk_perms')
win.set_checklist_selected('chk_perms', ['Read', 'Write'])

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
win.show_toast('Notice', 'Toast notification display')

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
win.add_form_input('form_username', 'Username:', 'Enter username...')
win.add_form_textarea('Biography:', 'form_bio', 'Developer and mathematician.')
win.add_form_password('Password:', 'form_pass', 'secret_key')
win.add_form_search('Search Catalog:', 'form_search', '')
win.add_form_dropdown('Country:', 'form_country', ['USA', 'Canada', 'UK'], 'USA')
win.add_form_list_box('Options:', 'form_list', ['Option A', 'Option B'], 'Option A')
win.add_form_multi_list_box('Tags:', 'form_multi_list', ['Tag 1', 'Tag 2'], ['Tag 1'])
win.add_form_combobox('Category:', 'form_combo', ['Cat A', 'Cat B'], 'Cat A')
win.add_form_switch('Notifications:', 'form_notify', 'Send Email Digest', true)
win.add_form_checkbox('Terms:', 'form_terms', 'I accept terms and conditions', true)
win.add_form_number('Quantity:', 'form_qty', 1)
win.add_form_slider('Volume:', 'form_vol', 80)
win.add_form_date_picker('Event Date:', 'form_date', '2026-12-25')
win.add_form_time_picker('Start Time:', 'form_time', '09:00')
win.add_form_file_picker('Upload Document:', 'form_file', '/tmp/data.csv')
win.add_form_color_picker('Theme Accent:', 'form_color', '#0a84ff')
win.add_form_progress('Download Progress:', 'form_prog', 45)
win.add_form_link('Website:', 'form_link', 'Visit Documentation', 'https://vlang.io')
```

---

## 7. Nameless RAD Shortcuts

Create controls without defining explicit string IDs:

```v
win.input('Default Text')
input_text := win.get_input()
area_text := win.get_textarea()

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
   .set_size(220, 42)
   .set_position(50, 100)
   .set_alignment('center')
   .set_placeholder('Enter text...')
   .set_text_align('left')
   .set_bg_color('#0a84ff')
   .set_accent_color('#0a84ff')
   .set_font_color('#ffffff')
   .set_font_size(15)
   .set_font_bold(true)
   .set_font_name('System')
   .set_corner_radius(8.0)
   .set_border(2.0, '#005bb5')
   .set_margin_xy(10, 5)
   .set_margin_trbl(10, 10, 5, 5)
   .set_margin_top(10)
   .set_margin_bottom(5)
   .set_margin_left(5)
   .set_margin_right(10)
   .set_padding_xy(16, 8)
   .set_padding_trbl(8, 16, 8, 16)
   .set_expand_fill(true)
   .set_visible(true)
   .set_enabled(true)
   .set_cursor('pointer')
   .set_tooltip('Click to submit your registration form')

// Undo history stack and selection queries on Control
btn.save_undo_state()
did_redo := btn.redo()
sel_start, sel_end := btn.selection_range()
```

### Direct Window Control Setter & Getter Reference

```v
win.set_control_width('btn_submit', 220)
w := win.get_control_width('btn_submit')

win.set_control_height('btn_submit', 42)
h := win.get_control_height('btn_submit')

win.set_control_size('btn_submit', 220, 42)
win.set_control_position('btn_submit', 50, 100)

win.set_control_font_size('btn_submit', 16)
fs := win.get_control_font_size('btn_submit')
win.set_control_font_bold('btn_submit', true)
win.set_control_font_name('btn_submit', 'Inter')
win.set_control_font_color('btn_submit', '#ffffff')

win.set_control_bg_color('btn_submit', '#10b981')
win.set_control_background_color('btn_submit', '#10b981') // Alias
win.set_control_accent_color('btn_submit', '#34c759')
win.set_control_border('btn_submit', 2.0, '#047857')
win.set_control_corner_radius('btn_submit', 6.0)

win.set_control_margin('btn_submit', 10)
m := win.get_control_margin('btn_submit')
win.set_control_margin_xy('btn_submit', 12, 6)
win.set_control_margin_trbl('btn_submit', 10, 12, 6, 12)

win.set_control_padding('btn_submit', 10)
p := win.get_control_padding('btn_submit')
win.set_control_padding_xy('btn_submit', 16, 8)
win.set_control_padding_trbl('btn_submit', 8, 16, 8, 16)

win.set_control_alignment('btn_submit', 'center')
align_str := win.get_control_alignment('btn_submit')

win.set_control_expand_fill('btn_submit', true)
exp_fill := win.get_control_expand_fill('btn_submit')

win.set_control_placeholder('input_user', 'Enter username...')
win.set_control_text_align('btn_submit', 'center')

win.set_control_tooltip('btn_submit', 'Hover helper tip')
tip := win.get_control_tooltip('btn_submit')

win.set_control_visible('btn_submit', true)
is_vis := win.get_control_visible('btn_submit')

win.set_control_enabled('btn_submit', true)
is_en := win.get_control_enabled('btn_submit')
win.set_control_opacity('btn_submit', 0.95)
```

### Linux & Cross-Platform Font Resolution

`simplegui` automatically resolves high-quality system TTF/OTF fonts on Linux distributions (such as Ubuntu, Debian, Fedora, Arch Linux, openSUSE, etc.) to ensure crisp, anti-aliased text rendering across all desktop screens.

```v
// Programmatically set a custom TTF font path
win.set_font_path('/path/to/custom_font.ttf')

// Environment variable override option:
// SIMPLEGUI_FONT_PATH=/path/to/myfont.ttf ./my_app

// Query resolved window font path or cross-platform candidate search lists
font_path := simplegui.resolve_window_font_path()
linux_candidates := simplegui.linux_font_candidates()
macos_candidates := simplegui.macos_font_candidates()
```

#### Linux System Font Resolution Search Order:

1. `SIMPLEGUI_FONT_PATH` environment variable override (if set and file exists).
2. `win.font_path` explicit window property configuration.
3. Ubuntu Font Family (`Ubuntu-R.ttf`, `Ubuntu-Regular.ttf`, `Ubuntu.ttf`).
4. Liberation Sans (`LiberationSans-Regular.ttf`).
5. DejaVu Sans (`DejaVuSans.ttf`).
6. Noto Sans (`NotoSans-Regular.ttf`).
7. Cantarell (`Cantarell-Regular.otf`).
8. FreeSans & Roboto (`FreeSans.ttf`, `Roboto-Regular.ttf`).
9. User Home Directory Fonts (`~/.local/share/fonts/`, `~/.fonts/`).

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

### Typed Safe Accessors & Safe Fallback Getters

```v
age := win.get_int('input_age')
win.set_int('input_age', 30)

price := win.get_f64('input_price')
win.set_f64('input_price', 19.99)
win.set_value_f64('input_price', 19.99)
val_f64 := win.get_value_f64('input_price', 10.0)

// Safe Fallback Getters (returns fallback value if control is unset or invalid)
name_str := win.get_text_or('input_name', 'Ada Lovelace')
val_or_str := win.get_value_or('input_field', 'Fallback Text')
is_check := win.get_bool_or('chk_terms', true)
num_int := win.get_int_or('input_qty', 1)
price_f64 := win.get_f64_or('input_price', 9.99)
num_val_int := win.get_value_int_or('input_qty', 1)
price_val_f64 := win.get_value_f64_or('input_price', 9.99)
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
win.bind_double_click('card_item', fn (mut win simplegui.SimpleWindow) {
	// Fluent binding alias for on_dblclick
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

// Window Form Submit Listener
win.on_submit(fn (mut win simplegui.SimpleWindow) {
	win.toast('Form submitted!')
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

// Enable or disable ALL controls in window
win.enable_all()
win.disable_all()

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

// Check if state key exists
if win.has_state('user_role') {
    println('State key registered!')
}

role := win.get_state('user_role')                    // string
count := win.get_state_int('counter')                 // int
is_dark := win.get_state_bool('dark_mode')           // bool
fallback_role := win.get_state_or('role', 'Guest')   // fallback if key unset
fallback_count := win.get_state_int_or('counter', 0)
fallback_flag := win.get_state_bool_or('flag', false)
fallback_scale := win.get_state_f64_or('scale', 1.0)

win.toggle_state_bool('dark_mode')        // Toggles boolean state
win.increment_state_int('counter', 1)     // Increments integer state

// Delete state entry or clear entire state store
win.remove_state('user_role')
win.clear_state()
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

### Environment & Process Management

```v
// Environment Variables
win.set_env('MY_APP_MODE', 'production')
val := win.get_env('MY_APP_MODE')
win.unset_env('MY_APP_MODE')

// Executables & Command Discovery
pid := win.get_pid()
uptime_sec := win.get_uptime_seconds()
exists := win.exists_in_path('git') // or win.has_command('git')
exec_path := win.find_executable('git') // or win.get_command_path('git')

// Exec in target directory
stdout, exit_code := win.exec_in_dir('/tmp', 'pwd')

// Process Control & Termination
is_running := win.is_process_running('nginx')
win.kill_process('nginx')
win.kill_process_by_pid(1234)
win.kill_process_by_name('nginx')
win.kill_process_exact('nginx')
```

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

### Desktop Notifications, Audio, Speech & Dialogs

```v
win.show_system_notification('Backup Complete', 'Your database backup was created successfully.')

// Audio Beeps & Sounds
win.beep()
win.beep_n(3)
win.play_system_sound('Ping')
simplegui.sys_beep()
simplegui.sys_beep_cross()
simplegui.play_system_sound('Glass')

// Speech Synthesis
win.say('Task complete')
win.speak_with_voice('Hello! Welcome to SimpleGUI.', 'Samantha')
simplegui.speak_with_voice('System online', 'Alex')

// System Volume & Mute
vol := win.get_volume()
win.set_volume(80)
muted := win.is_muted()
win.set_muted(false)

// Native macOS Scripting Dialogs
user_txt := win.osascript_dialog('Enter license key:', 'XXXX-XXXX')
is_ok := win.osascript_alert('Confirm Action', 'Proceed with installation?')
chosen_file := win.osascript_choose_file()
chosen_dir := win.osascript_choose_folder()
```

### Hardware Specs, System Info & Resource Monitoring

```v
cpu_name := win.get_cpu_info()
cpu_cores := win.get_cpu_cores()
memory_ram := win.get_memory_info()
screen_res := win.get_screen_resolution()
battery_pct := win.get_battery_percent()
is_charging := win.is_on_ac_power()

// Live Performance & Resource Metrics
cpu_pct := win.get_cpu_usage_percent()
load_1, load_5, load_15 := win.get_load_average()
mem_pressure := win.get_memory_pressure()
num_procs := win.get_running_process_count()
num_files := win.get_open_file_count()
swap_str := win.get_swap_usage()
```

### Directories, Files, Archives & Storage Specs

```v
home_path := win.get_system_path('home')
docs_path := win.get_system_path('documents')

// File & Directory Utilities
win.file_exists('/tmp/data.txt')
win.is_dir('/tmp/my_folder')
content := win.read_file('/tmp/data.txt')
opt_content := win.read_file_opt('/tmp/data.txt') or { '' }
win.write_file('/tmp/data.txt', 'Hello World')
win.write_file_opt('/tmp/data.txt', 'Hello World') or { return }
win.append_file('/tmp/log.txt', 'New Log Line\n') or { return }
win.touch_file('/tmp/newfile.txt') or { return }
win.delete_file('/tmp/temp.txt')
win.trash_file('/tmp/trash.txt') or { return }
win.create_directory('/tmp/new_dir')
dir_items := win.read_dir('/tmp')
dir_bytes := win.get_directory_size('/tmp/my_folder')
sha256_file_val := win.sha256_file('/tmp/data.txt') or { '' }
md5_file_val := win.md5_file('/tmp/data.txt') or { '' }

// File Metadata & Disk Space Specs
disk_info := win.get_disk_usage('/System/Volumes/Data') or { simplegui.DiskStats{} }
// disk_info.total_bytes, disk_info.free_bytes, disk_info.used_bytes, disk_info.used_percent
file_info := win.get_file_metadata('/tmp/data.txt') or { simplegui.FileMetadata{} }
// file_info.size_bytes, file_info.modified_time, file_info.is_dir, file_info.permissions

// Temporary File Creation
tmp_file := win.create_temp_file('app_', '.json') or { '' }
tmp_dir := win.create_temp_dir('session_') or { '' }

// Zip Archives
win.zip_directory('/tmp/source_dir', '/tmp/archive.zip') or { return }
win.unzip_archive('/tmp/archive.zip', '/tmp/dest_dir') or { return }

// Clipboard & External Openers
win.copy_to_clipboard('Copied text!')
clip_val := win.get_clipboard_text()

win.open_url('https://vlang.io')
win.reveal_in_finder('/tmp/my_folder')
win.open_in_default_app('/tmp/document.pdf')
win.open_with_app('/tmp/document.pdf', 'com.adobe.Reader')
win.open_terminal()
```

### Network Utilities & Port Scanning

```v
is_online := win.ping('8.8.8.8', 2)
local_ip := win.get_ip_address()
pub_ip := win.get_public_ip()

port_open := win.is_port_open('127.0.0.1', 8080)
free_port := win.find_available_port(8000)

win.download_file('https://vlang.io/robots.txt', '/tmp/robots.txt') or { return }
```

### macOS & System Platform Details

```v
macos_ver := win.get_macos_version()
macos_build := win.get_macos_build()
product_name := win.get_macos_product_name()
device_model := win.get_device_model()
serial_num := win.get_serial_number()
gpu_str := win.get_gpu_info()
bundle_id := win.get_app_bundle_id()
locale_str := win.get_system_locale()
tz_str := win.get_timezone()

// Launch at Login & Dock Badge
win.launch_at_login_add('/Applications/MyApp.app')
win.launch_at_login_remove('MyApp')
win.set_dock_badge(5)

// OS Dark Mode & System Theme
is_os_dark := win.is_dark_mode()
sys_theme := win.get_system_theme()
win.set_system_dark_mode(true)
win.set_system_theme('dark') or { return }
win.toggle_dark_mode()
simplegui.toggle_dark_mode()
```

### Power & User Session Control

```v
win.prevent_sleep_bg(3600) // Keep awake for 1 hour
win.sleep_display()
win.sleep_computer()
win.lock_screen()
win.start_screen_saver()
win.log_out_user()
win.restart_computer()
win.shut_down_computer()
```

---

## 14. V Standard Library Integrations

Built-in wrappers (`stdlib.v`) for V standard library operations.

### HTTP Requests

### HTTP Requests & Sockets

```v
// Basic GET & POST
body := win.http_get('https://api.ipify.org')
response := win.http_post('https://httpbin.org/post', '{"key":"value"}')

// Strict & Advanced HTTP Requests with headers/timeouts
strict_body := win.http_get_strict('https://api.ipify.org') or { '' }
post_strict := win.http_post_strict('https://httpbin.org/post', '{"key":"val"}') or { '' }
post_strict_g := simplegui.http_post_strict('https://httpbin.org/post', '{"key":"val"}') or { '' }
res := win.http_request(.post, 'https://api.example.com/data', '{"query":"test"}', simplegui.SimpleHttpRequestOptions{
    headers: {'Authorization': 'Bearer token123'}
    timeout_ms: 5000
}) or { simplegui.SimpleHttpResponse{} }

// Sockets & WebSockets
mut ws := win.websocket_client('ws://echo.websocket.org', fn (msg string) {
    println('WS Received: ${msg}')
}) or { return }
ws.write_string('Hello WebSocket')
ws.close()

mut tcp := win.tcp_connect('127.0.0.1:8080') or { return }
tcp.write('PING')
resp_bytes := tcp.read(1024) or { []u8{} }
tcp.close()

mut udp := win.udp_connect('127.0.0.1:9000') or { return }
udp.write('DATAGRAM')
udp.close()

mut unix_soc := win.unix_connect('/tmp/app.sock') or { return }
unix_soc.write('UNIX MSG')
unix_soc.close()
```

### Cryptography, Hashes & Security

```v
// Hashing Algorithms
sha256_hex := win.crypto_sha256('secret data')
md5_hex := win.crypto_md5('secret data')
sha512_hex := win.crypto_sha512('secret data')
sha1_hex := win.crypto_sha1('secret data')

// AES Symmetric Encryption & Secure Salted AES
key := '0123456789abcdef0123456789abcdef'
cipher_hex := win.crypto_encrypt_aes('plain_text', key)
decrypted := win.crypto_decrypt_aes(cipher_hex, key)

cipher_sec := win.crypto_encrypt_aes_secure('sensitive_data', 'passphrase123')
plain_sec := win.crypto_decrypt_aes_secure(cipher_sec, 'passphrase123')

// HMAC Signatures & Wyhash
hmac256 := win.crypto_hmac_sha256('message', 'secret')
hmac512 := win.crypto_hmac_sha512('message', 'secret')
hmac1 := win.crypto_hmac_sha1('message', 'secret')
wy_hash := win.crypto_wyhash('data', 12345)

// Bcrypt Password Hashing & Key Derivation (PBKDF2)
hash := win.crypto_bcrypt_hash('my_password') or { '' }
is_valid := win.crypto_bcrypt_verify('my_password', hash)
pbkdf2_key := win.crypto_pbkdf2('password', 'salt1234', 10000, 32)

// Cryptographic Randomness & Ed25519 Signatures
rand_bytes := win.crypto_rand_bytes(16)
rand_hex := win.crypto_rand_hex(16)
rand_uuid := win.crypto_rand_uuid()

keypair := win.crypto_ed25519_generate_key() or { simplegui.SimpleEd25519KeyPair{} }
sig := win.crypto_ed25519_sign(keypair.private_key, 'msg') or { []u8{} }
is_sig_valid := win.crypto_ed25519_verify(keypair.public_key, 'msg', sig)
```

### Compression Formats (Gzip, Zlib, Deflate, Zstd)

```v
gz_compressed := win.compress_gzip('Sample uncompressed string')
gz_decompressed := win.decompress_gzip(gz_compressed)

zlib_comp := win.compress_zlib('Sample text')
zlib_decomp := win.decompress_zlib(zlib_comp)

deflate_comp := win.compress_deflate('Sample text')
deflate_decomp := win.decompress_deflate(deflate_comp)

zstd_comp := win.compress_zstd('Sample text')
zstd_decomp := win.decompress_zstd(zstd_comp)
```

### RegEx, URL, HTML & Format Parsers

```v
// RegEx Pattern Matching & Strict Fallbacks
is_valid_email := win.regex_match('user@domain.com', r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
matches := win.regex_find('Order ID #12345', r'\d+')
replaced := win.regex_replace('Hello World', r'World', 'V')

is_match_strict := win.regex_match_strict('user@domain.com', r'^\w+@\w+\.\w+$') or { false }
is_match_strict_g := simplegui.regex_match_strict('user@domain.com', r'^\w+@\w+\.\w+$') or { false }
find_strict := win.regex_find_strict('Order ID #12345', r'\d+') or { []string{} }
find_strict_g := simplegui.regex_find_strict('Order ID #12345', r'\d+') or { []string{} }
replace_strict := win.regex_replace_strict('Hello World', r'World', 'V') or { '' }
replace_strict_g := simplegui.regex_replace_strict('Hello World', r'World', 'V') or { '' }

// URL Parsing & Construction
parsed_url := win.url_parse('https://example.com:8080/api/users?sort=asc')
// parsed_url.scheme, parsed_url.host, parsed_url.port, parsed_url.path, parsed_url.query
built_url := win.url_build('https', 'example.com', '/api/users', {'sort': 'asc'})

// HTML Document Parsing
html_doc := win.html_parse('<div class="header"><h1>Title</h1><a href="/link">Click</a></div>')
h1_text := html_doc.get_tag_text('h1')
class_nodes := html_doc.get_tags_by_class('header')
all_links := html_doc.get_all_links()
clean_text := html_doc.strip_tags()

// TOML, CSV, JSON & Base64 Parsers
toml_doc := win.toml_parse('title = "App Config"\nversion = 2')
app_title := toml_doc.get_string('title')

csv_rows := win.csv_parse("Name,Age\nAda,30\nAlan,40")
csv_out := win.csv_encode(csv_rows)

json_str := win.json_encode_map_list([{'name': 'Ada'}, {'name': 'Alan'}])
json_valid := win.json_validate(json_str)
pretty_json := win.json_pretty_print(json_str)

b64_enc := win.base64_encode('Hello')
b64_dec := win.base64_decode(b64_enc)
lorem_txt := win.lorem_generate('latin', 1, 2, 20)
```

### Generic Data Structures & Collections

```v
// Stack (LIFO)
mut stack := simplegui.new_stack[string]()
stack.push('item1')
top_item := stack.peek() or { '' }
is_stk_empty := stack.is_empty()
item := stack.pop()

// Queue (FIFO)
mut queue := simplegui.new_queue[int]()
queue.push(10)
top_q := queue.peek() or { 0 }
is_q_empty := queue.is_empty()
val := queue.pop()

// Set (Unique Values)
mut set := simplegui.new_set[string]()
set.add('tag1')
has_tag := set.exists('tag1')
is_set_empty := set.is_empty()
set_items := set.to_array()

// Ring Buffer (Circular Fixed Capacity)
mut ring := simplegui.new_ringbuffer[f64](5)
ring.push(1.23)
ring_cap := ring.capacity()
is_ring_empty := ring.is_empty()

// Min Heap (Priority Queue)
mut heap := simplegui.new_min_heap[int]()
heap.push(42)
heap_top := heap.peek() or { 0 }
min_val := heap.pop()
```

### Time, Benchmarks & Thread Sync

```v
now_str := win.time_now()
unix_ts := win.time_unix_timestamp()
ts_str := win.time_from_unix(unix_ts)
is_leap := win.time_is_leap_year(2026)
days := win.time_days_in_month(2026, 2)

// Stopwatch & Benchmark Suites
mut sw := win.start_stopwatch()
elapsed_ms := win.stopwatch_elapsed_ms(sw)
elapsed_sec := sw.elapsed_sec()

mut bench := simplegui.start_benchmark()
mut bench_new := simplegui.new_benchmark()
mut bench_win := win.new_benchmark()
bench.step()
bench.measure('Operation timing')
bench.ok()
bench.fail()
step_msg := bench.step_message('Step 1')
total_msg := bench.total_message('Complete Run')

// Thread Synchronization
mut mtx := simplegui.new_mutex()
mtx.lock()
mtx.unlock()

mut wg := simplegui.new_wait_group()
wg.add(2)
wg.done()
wg.wait()
```

### Advanced Math, Statistics & String Metrics

```v
// Trigonometry, Exponentials & Interpolation (Window & Module Standalone)
rad := win.math_radians(180.0)
deg := win.math_degrees(3.14159)
hyp := win.math_hypot(3.0, 4.0)
gcd_val := win.math_gcd(12, 18)
lcm_val := win.math_lcm(12, 18)
remapped := win.math_remap(50.0, 0.0, 100.0, 0.0, 1.0)
smoothed := win.math_smoothstep(0.0, 1.0, 0.5)

sin_val := win.math_sin(1.57)
sin_g := simplegui.math_sin(1.57)
cos_val := win.math_cos(3.14)
cos_g := simplegui.math_cos(3.14)
tan_val := win.math_tan(0.78)
tan_g := simplegui.math_tan(0.78)
sqrt_val := win.math_sqrt(16.0)
sqrt_g := simplegui.math_sqrt(16.0)
pow_val := win.math_pow(2.0, 8.0)
pow_g := simplegui.math_pow(2.0, 8.0)
abs_val := win.math_abs(-42.0)
abs_g := simplegui.math_abs(-42.0)
clamp_val := win.math_clamp(150.0, 0.0, 100.0)
clamp_g := simplegui.math_clamp(150.0, 0.0, 100.0)
round_val := win.math_round(3.56)
round_g := simplegui.math_round(3.56)
floor_val := win.math_floor(3.99)
floor_g := simplegui.math_floor(3.99)
ceil_val := win.math_ceil(3.01)
ceil_g := simplegui.math_ceil(3.01)
atan2_val := win.math_atan2(1.0, 1.0)
atan2_g := simplegui.math_atan2(1.0, 1.0)
log10_val := win.math_log10(100.0)
log10_g := simplegui.math_log10(100.0)
log2_val := win.math_log2(8.0)
log2_g := simplegui.math_log2(8.0)
round_sig_val := win.math_round_sig(3.14159, 3)
round_sig_g := simplegui.math_round_sig(3.14159, 3)

// Complex Numbers
mut c1 := simplegui.complex_new(3.0, 4.0)
c_abs := c1.abs()

// Arbitrary Precision BigInt
mut b1 := simplegui.big_int_from_str('12345678901234567890')
mut b2 := simplegui.big_int_from_int(100)
b3 := b1.add(b2)

// Statistical Calculations (Window & Module Standalone)
mean_val := win.stats_mean([1.0, 2.0, 3.0, 4.0, 5.0])
med_val := win.stats_median([1.0, 2.0, 3.0, 4.0, 5.0])
std_dev := win.stats_sample_std_dev([1.0, 2.0, 3.0, 4.0, 5.0])
geo_mean := win.stats_geometric_mean([1.0, 2.0, 3.0, 4.0, 5.0])
harm_mean := win.stats_harmonic_mean([1.0, 2.0, 3.0, 4.0, 5.0])
rms_val := win.stats_rms([1.0, 2.0, 3.0, 4.0, 5.0])
cov_val := win.stats_covariance([1.0, 2.0, 3.0], [4.0, 5.0, 6.0])

sample_var := win.stats_sample_variance([1.0, 2.0, 3.0, 4.0])
sample_v_g := simplegui.stats_sample_variance([1.0, 2.0, 3.0, 4.0])
pop_var := win.stats_population_variance([1.0, 2.0, 3.0, 4.0])
pop_v_g := simplegui.stats_population_variance([1.0, 2.0, 3.0, 4.0])
pop_sd := win.stats_population_std_dev([1.0, 2.0, 3.0, 4.0])
pop_sd_g := simplegui.stats_population_std_dev([1.0, 2.0, 3.0, 4.0])
mode_val := win.stats_mode([1.0, 2.0, 2.0, 3.0])
mode_g := simplegui.stats_mode([1.0, 2.0, 2.0, 3.0])
range_val := win.stats_range([1.0, 5.0, 10.0])
range_g := simplegui.stats_range([1.0, 5.0, 10.0])
kurt_val := win.stats_kurtosis([1.0, 2.0, 3.0, 4.0])
kurt_g := simplegui.stats_kurtosis([1.0, 2.0, 3.0, 4.0])
skew_val := win.stats_skew([1.0, 2.0, 3.0, 4.0])
skew_g := simplegui.stats_skew([1.0, 2.0, 3.0, 4.0])

// Array Utilities (Window & Module Standalone)
arr_min_i := win.array_min([10, 20, 5])
arr_min_ig := simplegui.array_min([10, 20, 5])
arr_max_i := win.array_max([10, 20, 5])
arr_max_ig := simplegui.array_max([10, 20, 5])
arr_min_f := win.array_min_f64([10.5, 20.2, 5.1])
arr_min_fg := simplegui.array_min_f64([10.5, 20.2, 5.1])
arr_max_f := win.array_max_f64([10.5, 20.2, 5.1])
arr_max_fg := simplegui.array_max_f64([10.5, 20.2, 5.1])
arr_sum_i := win.array_sum([10, 20, 30])
arr_sum_ig := simplegui.array_sum([10, 20, 30])
arr_sum_f := win.array_sum_f64([10.5, 20.5])
arr_sum_fg := simplegui.array_sum_f64([10.5, 20.5])
arr_uniq_s := win.array_unique_strings(['a', 'b', 'a'])
arr_uniq_sg := simplegui.array_unique_strings(['a', 'b', 'a'])

// UTF-8 Helpers
utf8_l := win.utf8_len('Hello V')
utf8_lg := simplegui.utf8_len('Hello V')
utf8_v := win.utf8_is_valid('Hello V')
utf8_vg := simplegui.utf8_is_valid('Hello V')

// String Padding & Repeat (Window & Module Standalone)
pad_l := win.string_pad_left('42', 5, '0')
pad_lg := simplegui.string_pad_left('42', 5, '0')
pad_r := win.string_pad_right('42', 5, '0')
pad_rg := simplegui.string_pad_right('42', 5, '0')
rep_s := win.string_repeat('V', 3)
rep_sg := simplegui.string_repeat('V', 3)

// Random Utilities & Choice Functions (Window & Module Standalone)
rand_i := win.rand_int(1, 100)
rand_ig := simplegui.rand_int(1, 100)
rand_s := win.rand_string(16)
rand_sg := simplegui.rand_string(16)

mut arr_s := ['apple', 'banana', 'cherry']
win.rand_shuffle_strings(mut arr_s)
simplegui.rand_shuffle_strings(mut arr_s)

choice_s := win.rand_choice_strings(arr_s)
choice_sg := simplegui.rand_choice_strings(arr_s)
choice_i := win.rand_choice_ints([10, 20, 30])
choice_ig := simplegui.rand_choice_ints([10, 20, 30])

w_choice_s := win.rand_weighted_choice_strings(['low', 'high'], [0.8, 0.2])
w_choice_sg := simplegui.rand_weighted_choice_strings(['low', 'high'], [0.8, 0.2])
w_choice_i := win.rand_weighted_choice_ints([1, 2], [0.9, 0.1])
w_choice_ig := simplegui.rand_weighted_choice_ints([1, 2], [0.9, 0.1])

// Hex & Base64 Encoders / Decoders
hex_e := win.hex_encode('Hello')
hex_eg := simplegui.hex_encode('Hello')
hex_d := win.hex_decode(hex_e)
hex_dg := simplegui.hex_decode(hex_e)

// SemVer Comparison & Version Queries
sem_c := win.semver_compare('1.2.0', '1.1.5')
sem_cg := simplegui.semver_compare('1.2.0', '1.1.5')
sem_s := win.semver_satisfies('1.2.0', '>=1.0.0')
sem_sg := simplegui.semver_satisfies('1.2.0', '>=1.0.0')

// URL Encoders & Decoders
url_enc := win.url_encode('hello world')
url_enc_g := simplegui.url_encode('hello world')
url_dec := win.url_decode('hello%20world')
url_dec_g := simplegui.url_decode('hello%20world')

// Formatted Time & Terminal Colors
time_e := win.time_elapsed(3600000)
time_eg := simplegui.time_elapsed(3600000)
term_c := win.term_color('Warning', 'yellow')
term_cg := simplegui.term_color('Warning', 'yellow')

// JSON Map Decoders
json_m := win.json_decode_map('{"key":"val"}')
json_mg := simplegui.json_decode_map('{"key":"val"}')
json_ms := win.json_decode_map_strict('{"key":"val"}') or { map[string]string{} }
json_msg := simplegui.json_decode_map_strict('{"key":"val"}') or { map[string]string{} }
json_ml := win.json_decode_map_list('[{"key":"val"}]')
json_mlg := simplegui.json_decode_map_list('[{"key":"val"}]')

// CSV Column Extraction & Filtering
csv_col := win.csv_extract_column(csv_rows, 0)
csv_colg := simplegui.csv_extract_column(csv_rows, 0)
csv_filt := win.csv_filter_by_column(csv_rows, 1, '30')
csv_filtg := simplegui.csv_filter_by_column(csv_rows, 1, '30')

// StringBuilder & Complex Conjugate
mut ssb := simplegui.new_string_builder()
mut ssb_w := win.new_string_builder()
ssb.write_line('Line text')
c_conj := c1.conj()

// HTML & URL Methods
url_built := parsed_url.build_url()
html_attr := html_doc.get_attr('a', 'href')
html_imgs := html_doc.get_all_images()
toml_def := toml_doc.get_string_default('name', 'DefaultApp')

// String Metrics & Similarity
lev_dist := win.string_levenshtein('kitten', 'sitting')
jaro_sim := win.string_jaro_similarity('martha', 'marhta')
jw_sim := win.string_jaro_winkler_similarity('dwayne', 'duane')
ham_dist := win.string_hamming_distance('karolin', 'kathrin')
between := win.string_between('<span>hello</span>', '<span>', '</span>')
word_cnt := win.string_count_words('The quick brown fox jumps')
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
simplegui.clipboard_copy('Text to copy') // Alias
clip_text := simplegui.read_clipboard()
clip_text_alias := simplegui.clipboard_read() // Alias

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

// Internal timer processing tick
win.process_timers()
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

## 19. Cross-Window Spy++ & External App Automation

`simplegui` includes a powerful cross-window registry, remote inter-window control, a live event bus, and macOS external application inspection via AXUIElement (`sys.v`).

### 1. Cross-Window Registry & Remote Inspection (Spy++)

Register windows in a global process registry to inspect, message, or manipulate controls on other active application windows:

```v
// Register / Unregister window in global registry
simplegui.sys_register_window(win)
simplegui.sys_unregister_window('Dashboard Manager')

// List all registered window titles ([]string)
win_titles := simplegui.sys_list_app_windows()

// Lookup window reference pointer by title
if mut app_win := simplegui.sys_get_window('Dashboard Manager') {
    app_win.show()
}

// Order window z-index or visibility remotely
simplegui.sys_order_app_window_front('Settings Window')
simplegui.sys_order_app_window_back('Settings Window')
simplegui.sys_set_app_window_visible('Settings Window', false)

// Spy and inspect controls on target window ([]ControlInfo)
if ctrl_info_list := simplegui.sys_spy_window('Dashboard Manager') {
    for info in ctrl_info_list {
        println('Control: ${info.name} | Kind: ${info.kind} | Value: ${info.value}')
    }
}

// Remote control state manipulation across windows
simplegui.sys_set_control_enabled('Dashboard Manager', 'btn_save', true)
simplegui.sys_set_control_visible('Dashboard Manager', 'lbl_status', true)
simplegui.sys_set_control_text('Dashboard Manager', 'lbl_status', 'Updated remotely')
val := simplegui.sys_get_control_text('Dashboard Manager', 'lbl_status')
simplegui.sys_flash_control('Dashboard Manager', 'btn_save')

// Single window remote methods
win.order_front()
win.order_back()
win.show_window()
ctrl_list := win.spy_controls()
win.flash_control('btn_save')
```

### 2. Cross-Window Live Event Bus

Subscribe to global event broadcasts across windows in the application:

```v
// Subscribe to cross-window event bus
simplegui.sys_subscribe_events(fn (win_title string, control_name string, event_name string, value string) {
    println('Event on [${win_title}] ${control_name}.${event_name} = ${value}')
})

// Broadcast custom event across subscriber callbacks
simplegui.sys_broadcast_event('MainWindow', 'tbl_users', 'row_selected', 'ID_101')
```

### 3. External macOS Application Automation (AXUIElement)

Inspect and automate external macOS applications via OS Accessibility APIs:

```v
// List all running external GUI desktop applications ([]ExternalAppInfo)
external_apps := simplegui.sys_list_external_apps()
for app in external_apps {
    println('App PID: ${app.pid} | Name: ${app.name} | Bundle: ${app.bundle_id}')
}

// Spy and inspect UI hierarchy on target external application by PID ([]ExternalControlInfo)
if external_apps.len > 0 {
    target_pid := external_apps[0].pid
    controls := simplegui.sys_spy_external_app(target_pid)
    for ctrl in controls {
        println('AXControl: ${ctrl.title} | Role: ${ctrl.role} | Value: ${ctrl.value}')
    }

    // Automate external application controls & visibility
    simplegui.sys_set_external_app_frontmost(target_pid)
    simplegui.sys_set_external_app_visible(target_pid, true)
    simplegui.sys_press_external_control(target_pid, 'Save')
    simplegui.sys_set_external_control_value(target_pid, 'Search Field', 'Query')
    simplegui.sys_set_external_control_enabled(target_pid, 'Submit Button', true)
    simplegui.sys_set_external_control_visible(target_pid, 'Submit Button', true)
    simplegui.sys_flash_external_control(target_pid, 'Save')
}
```

---

## 20. Modern Super Controls (Developer Heaven Catalog)

The **Modern Super Controls** suite provides next-generation, high-productivity UI components designed specifically to give developers an effortless, state-of-the-art experience when building modern dashboards, developer tools, administration panels, and interactive desktop apps.

Every super control is optimized with responsive vector graphics, zero external dependencies, seamless theme adaptation (Nord, Dracula, Apple Dark/Light, Cyberpunk, Emerald, etc.), and fluent chaining support.

### Super Controls Quick Reference Table

| Widget Method | Description | Primary Use Case |
|---|---|---|
| **`add_stat_card`** / **`add_metric_trend`** | KPI card with bold value, delta pill, and mini vector sparkline | Financial metrics, real-time KPI monitoring |
| **`add_code_studio`** | Code editor with window controls, language badge, line gutter & syntax colors | Dev tools, script runners, config editors |
| **`add_kanban_board`** / **`add_kanban_card`** | Multi-column Agile/Kanban task board with priority badges | Project management, task tracking workflows |
| **`add_activity_feed`** / **`add_feed_event`** | Real-time event timeline stream with status dots & time badges | Audit trails, deployment logs, system streams |
| **`add_donut_chart`** / **`add_radial_gauge`** | Circular donut gauge with smooth arc and percentage display | Resource gauges, memory/CPU meters, goals |
| **`add_terminal_console`** / **`log_terminal`** | Multi-tab developer terminal with live pulse indicator & log levels | Build output, logs, REPL consoles |
| **`add_smart_table`** | Data grid with built-in search filter, sortable headers & pagination | Customer databases, orders, analytics tables |
| **`add_wizard_stepper`** / **`wizard_next`** | Multi-step onboarding and checkout workflow with checkmarks | Multi-page setup wizards, checkout flows |
| **`add_floating_toolbar`** | Glassmorphic capsule bar with title badge and action buttons | Header bars, floating action overlays |
| **`add_chip_input`** / **`add_chip`** | Interactive removable category chips with add button | Tag filtering, skill selectors, labels |
| **`add_score_card`** | Rating score card with 5-star distribution breakdown bars | Product reviews, user feedback analytics |

---

### 1. Super Stat Card (`add_stat_card` / `stat`)

Displays high-impact business metrics with a formatted value, delta trend pill (`+18.4%`), and mini vector sparkline trend graph.

```v
// Full Factory Syntax:
win.add_stat_card(
    'kpi_mrr',                          // Control Name / ID
    'Monthly Recurring Revenue',        // Metric Title
    '$184,520',                         // Large Formatted Value
    '+22.4% vs last mo',               // Delta Badge Text
    true,                               // is_positive trend (true = green, false = red)
    [20.0, 35.0, 30.0, 50.0, 45.0, 70.0, 85.0, 95.0] // Sparkline Data Points
)

// Update Values at Runtime:
win.set_stat_card('kpi_mrr', 'MRR', '$210,000', '+28.0%', true)

// Quick Nameless RAD Shortcut:
win.stat('Daily Active Users', '48,290', '+12.5%', true, [10.0, 15.0, 25.0, 40.0])
```

---

### 2. Super Code Studio (`add_code_studio` / `code_box`)

An interactive code studio with window action dots, filename header, language badge, line numbers gutter column, syntax-highlighted tokens, and one-click copy button.

```v
// Add Code Studio:
win.add_code_studio(
    'editor',                           // Control Name
    'server.v',                         // Filename
    'v',                                // Syntax Language ('v', 'json', 'sql', 'python', etc.)
    'module main\n\nimport simplegui\n\nfn main() {\n\tprintln(\'Hello Super Controls!\')\n}'
)

// Update Code Contents:
win.set_code_studio('editor', 'main.v', 'v', 'fn main() { println("Updated!") }')

// Quick Nameless RAD Shortcut:
win.code_box('query.sql', 'sql', 'SELECT id, name, email FROM users WHERE active = true;')
```

---

### 3. Super Kanban Board (`add_kanban_board` / `add_kanban_card` / `kanban`)

An Agile/Kanban board supporting multi-column layouts, task counts, and colored priority cards.

```v
// 1. Initialize Board with Columns:
win.add_kanban_board('task_board', ['Backlog', 'In Progress', 'Review', 'Done'])

// 2. Add Cards to Specific Columns (0-indexed column, format: 'TAG|PRIORITY|Title'):
win.add_kanban_card('task_board', 0, 'UI|HIGH|Design Super Controls')
win.add_kanban_card('task_board', 0, 'DOCS|MED|Write Developer Guide')
win.add_kanban_card('task_board', 1, 'CORE|HIGH|Implement Vector Render Engine')
win.add_kanban_card('task_board', 2, 'TEST|MED|Run Automated Unit Tests')
win.add_kanban_card('task_board', 3, 'PERF|LOW|Zero-Allocation Benchmarks')

// 3. Quick Nameless Shortcut:
win.kanban(['To Do', 'Doing', 'Done'])
```

---

### 4. Super Activity Feed (`add_activity_feed` / `add_feed_event`)

A real-time audit log and event stream featuring vertical connecting tracks, glowing status nodes (`[OK]`, `[WARN]`, `[ERR]`, `[INFO]`), and relative time stamps.

```v
// Initialize Activity Feed:
win.add_activity_feed('system_feed', [
    'DEPLOY|2m ago|Release v2.8 deployed to production',
    'OK|8m ago|All 42 automated tests passed in 1.4s',
    'WARN|22m ago|High memory watermark at 84%',
    'INFO|45m ago|Automated daily backup completed (2.4 GB)',
])

// Push New Events Dynamically:
win.add_feed_event('system_feed', 'New user registered: ada@vlang.io', 'just now', 'INFO')
```

---

### 5. Super Donut & Radial Gauge (`add_donut_chart` / `add_radial_gauge` / `donut`)

A circular progress meter and resource utilization gauge with smooth vector arc rendering and central percentage text.

```v
// Add Donut Chart / Radial Gauge:
win.add_donut_chart('cpu_gauge', 'CPU Core Load', 78.5)

// Alias:
win.add_radial_gauge('memory_gauge', 'RAM Usage', 62.0)

// Update Percentage at Runtime:
win.set_donut_percentage('cpu_gauge', 91.0)

// Quick Nameless Shortcut:
win.donut('Storage Free', 85.0)
```

---

### 6. Super Developer Terminal (`add_terminal_console` / `log_terminal` / `terminal`)

A full-featured developer console emulator with tabbed outputs (`Output`, `Build`, `Terminal`), live glowing pulse status dot, `[Clear]` button, and ANSI/log level color highlighting.

```v
// Initialize Terminal Console:
win.add_terminal_console('dev_term', ['Output', 'Build Server', 'Audit Log', 'Debug Console'])

// Append Color-Coded Log Messages:
win.log_terminal('dev_term', '[INFO] SimpleGUI v1.0.0 initializing graphics context...')
win.log_terminal('dev_term', '[OK] Metal / OpenGL acceleration active (60 FPS)')
win.log_terminal('dev_term', '[WARN] Cache miss for user session')
win.log_terminal('dev_term', '[ERR] Connection timeout on worker #3')
win.log_terminal('dev_term', '[SUCCESS] All systems operational!')

// Clear Terminal Logs:
win.clear_terminal('dev_term')

// Quick Nameless Shortcut:
win.terminal(['Logs', 'Server'])
```

---

### 7. Super Smart Table (`add_smart_table`)

A next-generation data table featuring integrated search filter inputs, sortable column headers (`▲`/`▼`), status badge cell renderers, and pagination navigation.

```v
headers := ['ID', 'Customer', 'Status', 'MRR', 'Plan']
rows := [
    ['#101', 'Ada Lovelace', 'Active', '$1,450', 'Enterprise'],
    ['#102', 'Grace Hopper', 'Done', '$899', 'Pro'],
    ['#103', 'Alan Turing', 'Pending', '$499', 'Team'],
    ['#104', 'Margaret Hamilton', 'Active', '$2,200', 'Enterprise'],
    ['#105', 'Claude Shannon', 'Review', '$299', 'Starter'],
]

// Add Smart Table:
win.add_smart_table('customers_grid', headers, rows)

// Event Listener on Row Selection:
win.on_row_click('customers_grid', fn (mut win simplegui.SimpleWindow) {
    ctrl := win.control('customers_grid')
    println('Selected row index: ${ctrl.selected_row}')
})
```

---

### 8. Super Wizard Stepper (`add_wizard_stepper` / `wizard_next` / `wizard`)

A multi-step configuration, setup, and onboarding stepper with progress track lines, completion checkmarks, and active glowing indicators.

```v
// Initialize Wizard Stepper:
win.add_wizard_stepper('deploy_wizard', [
    'Configuration',
    'Build & Test',
    'Security Audit',
    'Cloud Deploy',
], 1) // Active Step Index: 1 (Build & Test)

// Programmatic Navigation:
win.wizard_next('deploy_wizard')        // Advance to step 2
win.wizard_prev('deploy_wizard')        // Back to step 1
win.set_wizard_step('deploy_wizard', 3) // Jump directly to step 3

// Quick Nameless Shortcut:
win.wizard(['Step 1', 'Step 2', 'Step 3'], 0)
```

---

### 9. Super Floating Action Bar (`add_floating_toolbar`)

A glassmorphic capsule floating toolbar with brand title and interactive action pills.

```v
// Add Floating Toolbar:
win.add_floating_toolbar('hero_bar', 'DevStudio Pro', [
    'Dashboard',
    'Code Studio',
    'Kanban',
    'Terminal',
    'Settings',
])

// Event Listener on Action Click:
win.on_click('hero_bar', fn (mut win simplegui.SimpleWindow) {
    selected_action := win.control('hero_bar').text_value
    win.show_toast('Action Selected', 'Switched to view: ${selected_action}')
})
```

---

### 10. Super Chip Input Cloud (`add_chip_input` / `add_chip` / `chips`)

An interactive tag/chip cloud with removable category badges and quick add button.

```v
// Add Chip Cloud:
win.add_chip_input('tags_cloud', ['VLang', 'Native UI', 'Fast', 'Zero Dependencies'])

// Add / Remove Chips Dynamically:
win.add_chip('tags_cloud', 'SuperControls')
win.remove_chip('tags_cloud', 'Fast')

// Quick Nameless Shortcut:
win.chips(['Frontend', 'Backend', 'Security', 'Performance'])
```

---

### 11. Super Score Card (`add_score_card`)

A feature review & rating scorecard with large formatted score (`4.9 / 5.0`), vector stars, review count, and 5-star breakdown distribution bars.

```v
// Add Score Card:
win.add_score_card(
    'score_happiness',                  // Control Name
    'Developer Satisfaction',           // Title Header
    4.95,                               // Numeric Score (out of 5.0)
    3840,                               // Total Reviews Count
    [92.0, 6.0, 1.2, 0.5, 0.3]          // Percentage Breakdown for [5★, 4★, 3★, 2★, 1★]
)
```

---

## 21. Modern Image Super Controls & Developer Asset Catalog

`simplegui` includes a powerful hardware-accelerated image rendering engine with automatic GPU texture caching, graceful vector fallbacks, and a collection of high-impact image controls that modern desktop applications demand.

### Bundled Developer Asset Catalog (`assets/images/`)

`simplegui` bundles high-resolution developer and user image assets ready for instant use:

| Asset Path                                      | Dimensions | Category       | Description / Intended Use Cases                                      |
| ----------------------------------------------- | ---------- | -------------- | --------------------------------------------------------------------- |
| `assets/images/avatar_ada_lovelace.jpg`         | 1024x1024  | Avatar         | Professional 3D female software architect avatar portrait (Ada).      |
| `assets/images/avatar_alex_chen.jpg`             | 1024x1024  | Avatar         | Friendly 3D male full-stack developer / SRE avatar portrait (Alex).   |
| `assets/images/banner_cloud_devops.jpg`         | 1792x1024  | Hero / Banner  | Cybernetic cloud datacenter & telemetry data stream infrastructure.   |
| `assets/images/banner_ai_code_studio.jpg`       | 1792x1024  | Hero / Banner  | Neural AI code studio workstation with holographic syntax windows.    |
| `assets/images/banner_cyber_security.jpg`       | 1792x1024  | Hero / Banner  | Global cyber defense operations center with active holographic shield.|
| `assets/images/icon_db_engine.jpg`              | 1024x1024  | 3D App Icon    | High-performance distributed SQL / Key-Value database cylinder icon.  |
| `assets/images/icon_rocket_deploy.jpg`          | 1024x1024  | 3D App Icon    | Futuristic spacecraft rocket launching for continuous cloud deploy.   |
| `assets/images/icon_terminal_cli.jpg`           | 1024x1024  | 3D App Icon    | Interactive developer terminal CLI console with glowing prompts.      |
| `assets/images/cover_lofi_beats.jpg`            | 1024x1024  | Media / Cover  | Synthwave & Lo-Fi developer coding music album cover art.             |
| `assets/images/product_dev_station.jpg`         | 1792x1024  | Product / Shop | Luxury custom mechanical keyboard with walnut finish and RGB glow.    |

---

### 1. User Profile Card (`add_user_profile_card` / `user_profile`)

A modern user/developer profile card featuring an avatar image, online/offline status indicator dot, full name, username handle (`@dev`), role pill badge, bio description, and interactive action button.

```v
// Add User Profile Card:
win.add_user_profile_card(
    'prof_ada',                             // Control ID
    'assets/images/avatar_ada_lovelace.jpg',// Avatar image path
    'Ada Lovelace',                         // Full Name
    '@ada_lovelace',                        // Username handle
    'Lead Systems Architect',               // Role Badge
    'Pioneering computing visionary and V language enthusiast.', // Bio
    true,                                   // Online status (true = green dot)
    '[Connect]'                             // Action button label
)

// Dynamic status mutation:
win.set_user_online_status('prof_ada', false) // Sets status dot to gray

// Method chaining setter:
win.control('prof_ada').set_user_profile(
    'assets/images/avatar_alex_chen.jpg',
    'Alex Chen',
    '@alex_dev',
    'Senior SRE',
    'Cloud distributed systems developer.',
    true
)

// Event listener on action button click:
win.on_click('prof_ada', fn (mut win simplegui.SimpleWindow) {
    win.show_toast('Profile', 'Opened communication channel!')
})

// Quick Nameless Shortcut:
win.user_profile('assets/images/avatar_ada_lovelace.jpg', 'Ada Lovelace', '@ada', 'Architect', 'Systems Lead')
```

---

### 2. Modern Product Card (`add_product_card` / `product_card`)

An e-commerce, store, or SaaS tier showcase card featuring a top hero image, floating badge tag (`BESTSELLER`, `PRO`, `SALE`), product title, subtitle, formatted price tag, star rating, and CTA action button.

```v
// Add Product Card:
win.add_product_card(
    'prod_keyboard',                         // Control ID
    'assets/images/product_dev_station.jpg', // Product hero image
    'Custom Macro Station',                  // Title
    'Premium mechanical keyboard with walnut finish & RGB underglow', // Description
    '$189.00',                               // Price tag
    'BESTSELLER',                            // Floating Badge Tag
    '[Buy Now]'                              // Action Button text
)

// Event listener:
win.on_click('prod_keyboard', fn (mut win simplegui.SimpleWindow) {
    win.show_toast('Cart', 'Added product to your checkout cart!')
})

// Quick Nameless Shortcut:
win.product_card('assets/images/product_dev_station.jpg', 'Macro Keypad', '$89.00')
```

---

### 3. Interactive Image Gallery (`add_image_gallery` / `gallery`)

A multi-image carousel and photo viewer featuring a large hero preview, `< Prev` and `Next >` navigation buttons, slide caption banner, slide counter (`2 / 3`), and a clickable thumbnail navigation strip at the bottom.

```v
gallery_images := [
    'assets/images/banner_cloud_devops.jpg',
    'assets/images/banner_ai_code_studio.jpg',
    'assets/images/banner_cyber_security.jpg',
]
gallery_captions := [
    'Cybernetic Cloud Datacenter Infrastructure',
    'Neural AI Code Studio Workstation',
    'Global Cyber Defense Operations Center',
]

// Add Image Gallery:
win.add_image_gallery('showcase_gallery', gallery_images, gallery_captions, 0)

// Programmatic Slide Navigation:
win.next_gallery_image('showcase_gallery') // Advance to next slide
win.prev_gallery_image('showcase_gallery') // Go to previous slide
win.set_gallery_index('showcase_gallery', 2) // Jump directly to slide index 2

// Event listener on slide change:
win.on_click('showcase_gallery', fn (mut win simplegui.SimpleWindow) {
    ctrl := win.control('showcase_gallery')
    println('Active gallery slide index: ${ctrl.int_value}')
})

// Quick Nameless Shortcut:
win.gallery(gallery_images)
```

---

### 4. 3D App / Tool Launcher Tile (`add_app_launcher_tile` / `app_tile`)

An application or tool tile featuring a 3D isometric app icon, title, category/tagline, status pill indicator (`ONLINE`, `DEPLOYING`, `READY`), and hover elevation effects.

```v
// Add App Launcher Tiles:
win.add_app_launcher_tile(
    'tool_db',
    'assets/images/icon_db_engine.jpg',
    'Cyber DB Engine',
    'High-Performance Key-Value & SQL',
    'ONLINE'
)
win.add_app_launcher_tile(
    'tool_deploy',
    'assets/images/icon_rocket_deploy.jpg',
    'Continuous Delivery',
    'Zero-Downtime Cloud Pipeline',
    'DEPLOYING'
)

// Event listener:
win.on_click('tool_db', fn (mut win simplegui.SimpleWindow) {
    win.show_toast('Launcher', 'Connected to database cluster.')
})

// Quick Nameless Shortcut:
win.app_tile('assets/images/icon_terminal_cli.jpg', 'DevStudio CLI', 'READY')
```

---

### 5. Audio & Media Player Card (`add_media_player` / `media_player`)

A music and podcast streaming player card featuring square album cover art, track title, artist subtitle, interactive playback track scrubber with formatted timestamps (`01:18 / 04:00`), and play/pause toggle controls.

```v
// Add Media Player:
win.add_media_player(
    'synth_player',
    'assets/images/cover_lofi_beats.jpg',
    'Lo-Fi Code & Beats (Synthwave Journey)',
    'Cybernetic Waves Presents • 198X High-Fidelity',
    240,    // Track duration in seconds (4:00)
    78,     // Elapsed time in seconds (1:18)
    true    // Is playing (true = playing, false = paused)
)

// Programmatic Media Controls:
win.toggle_media_player('synth_player')             // Toggle play / pause
win.set_media_player_progress('synth_player', 120)  // Seek to 2:00 (120 seconds)

// Event listener:
win.on_click('synth_player', fn (mut win simplegui.SimpleWindow) {
    ctrl := win.control('synth_player')
    println('Player state - Playing: ${ctrl.bool_value}, Elapsed: ${ctrl.min_val}s')
})

// Quick Nameless Shortcut:
win.media_player('assets/images/cover_lofi_beats.jpg', 'Coding Focus', 'Cybernetic Waves')
```

---

### 6. Hero Introduction Banner (`add_hero_banner` / `hero_banner`)

A high-impact promotional or welcome card featuring a hero illustration graphic on the right, bold headline, descriptive tagline, and primary/secondary CTA buttons.

```v
// Add Hero Banner:
win.add_hero_banner(
    'hero_cloud',
    'assets/images/banner_cloud_devops.jpg',
    'Cloud Infrastructure & DevOps Suite',
    'Deploy microservices, inspect live telemetry streams, and manage clusters with native 60 FPS performance.',
    '[Launch Cluster]'
)

// Event listener:
win.on_click('hero_cloud', fn (mut win simplegui.SimpleWindow) {
    win.show_toast('Hero Action', 'Initializing cloud infrastructure...')
})

// Quick Nameless Shortcut:
win.hero_banner('assets/images/banner_ai_code_studio.jpg', 'AI Code Studio Pro', 'Next-generation intelligent code generation.')
```

---

### 7. Standalone Image Box (`add_image_box` / `image_box`)

A standalone image container with custom width/height, automatic texture caching, rounded border corners, and optional bottom caption banner.

```v
// Add Image Box with dimensions (320px width x 240px height):
win.add_image_box('sec_preview', 'assets/images/banner_cyber_security.jpg', 320, 240)

// Quick Nameless Shortcut:
win.image_box('assets/images/icon_rocket_deploy.jpg', 64, 64)
```

---

## 22. Type & Struct Reference Index



A reference index of core data structures, callback aliases, and configuration structs across `simplegui`.

### Callback Type Aliases

| Callback Type Alias           | Signature / Definition                                                        | Description                                                   |
| ----------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------- |
| **`VoidEventCallback`**       | `fn (mut win SimpleWindow)`                                                   | Default widget event handler callback                         |
| **`ControlValidator`**        | `fn (val string) bool`                                                        | Custom validation function for form inputs                    |
| **`StringEventCallback`**     | `fn (mut win SimpleWindow, val string)`                                       | Reactive state string mutation callback                       |
| **`FileDropCallback`**        | `fn (mut win SimpleWindow, files []string)`                                   | Native OS drag-and-drop files callback                        |
| **`CloseRequestedCallback`**  | `fn (mut win SimpleWindow) bool`                                              | Intercept window close request (return false to cancel close) |
| **`AnyEventCallback`**        | `fn (mut win SimpleWindow, event_type string, ctrl_name string)`              | Catch-all event listener                                      |
| **`SystemEventCallback`**     | `fn (win_title string, control_name string, event_name string, value string)` | Cross-window event bus subscriber callback                    |
| **`SimpleWSMessageCallback`** | `fn (msg string)`                                                             | WebSocket incoming text payload listener                      |

### Core Struct Definitions

#### `simplegui.Control`

The core rendering and state container for every widget inside `SimpleWindow`:

- **Identification**: `name string`, `kind string`, `title string`, `placeholder string`, `tooltip string`, `variant string`
- **Geometry & Bounds**: `x f32`, `y f32`, `w f32`, `h f32`, `padding_left f32`, `padding_right f32`, `padding_top f32`, `padding_bottom f32`, `margin_left f32`, `margin_right f32`, `margin_top f32`, `margin_bottom f32`, `alignment string`, `expand_fill bool`
- **Values & Data**: `text_value string`, `int_value int`, `bool_value bool`, `f64_value f64`, `items []string`, `items_selected []string`, `tags []string`, `rows [][]string`, `headers []string`
- **Styling**: `bg_color string`, `font_color string`, `accent_color string`, `font_size int`, `font_bold bool`, `font_name string`, `border_width f32`, `border_color string`, `corner_radius f32`, `opacity f64`
- **States & Handlers**: `disabled bool`, `visible bool`, `focused bool`, `hovered bool`, `validation_err string`, `on_click VoidEventCallback`, `on_change VoidEventCallback`, `on_enter VoidEventCallback`

#### `simplegui.Theme`

Theme configuration definition:

- `name string`: Theme display name
- `background_color string`: Main window background hex color
- `font_color string`: Text typography hex color
- `accent_color string`: Active accent highlight hex color
- `hover_color string`: Interactive hover highlight color
- `surface_hover string`: Surface card hover background color
- `description string`: Theme description text
- `is_dark bool`: Boolean flag indicating dark or light theme

#### `simplegui.TreeNode`

Recursive tree structure node for `add_tree_view`:

- `title string`: Label text for tree item
- `children []TreeNode`: Array of child nodes

#### `simplegui.ToolbarItem`

Item descriptor for `add_toolbar`:

- `icon string`: Symbol/text icon string
- `tooltip string`: Hover tooltip text
- `on_click VoidEventCallback`: Click callback

#### `simplegui.PropertyGridItem`

Key-value entry for `add_property_grid`:

- `name string`: Property label name
- `val string`: Current property text representation
- `kind string`: Property input type (`text`, `bool`, `color`, `number`)

#### `simplegui.Toast`

Toast notification alert item:

- `id string`, `title string`, `message string`, `variant string` (`info`, `success`, `warning`, `error`), `duration_ms int`, `remaining f32`

#### `simplegui.CommandItem`

Command descriptor for `show_command_palette`:

- `id string`, `title string`, `category string`, `shortcut string`, `on_execute VoidEventCallback`

#### `simplegui.ContextMenuItem`

Menu item for `show_context_menu`:

- `id string`, `title string`, `shortcut string`, `on_select VoidEventCallback`

#### `simplegui.CommandResult`, `simplegui.DiskStats` & `simplegui.FileMetadata`

- **`CommandResult`**: `command string`, `output string`, `exit_code int`, `timed_out bool`, `duration_ms i64`, `attempts int`
- **`DiskStats`**: `total u64`, `available u64`, `used u64`
- **`FileMetadata`**: `size i64`, `inode u64`, `nlink u64`, `dev u64`, `uid u32`, `gid u32`, `mode u32`, `atime i64`, `mtime i64`, `ctime i64`, `is_dir bool`, `is_file bool`, `is_link bool`, `is_readable bool`, `is_writable bool`, `is_executable bool`

#### `simplegui.ExternalAppInfo` & `simplegui.ExternalControlInfo`

- **`ExternalAppInfo`**: `pid int`, `name string`, `bundle_id string`
- **`ExternalControlInfo`**: `role string`, `title string`, `value string`, `enabled bool`

#### `simplegui.WindowConfig`, `simplegui.WindowParams`, `simplegui.ControlInfo`

These are the data objects used for state persistence, window parameter creation, and inspection of live UI controls.

- **`WindowConfig`**: serializable values for title, dimensions, padding, spacing, colors, window flags, and draggable/titlebar flags.
- **`WindowParams`**: low-level int-based equivalent used by window construction and native interop.
- **`ControlInfo`**: exported metadata snapshot including `name`, `kind`, `label`, `value`, `checked`, `number`, `enabled`, `visible`, `width`, `height`, `placeholder`, `error_text`, `tooltip`, `background_color`, `font_color`, `font_size`.

#### `simplegui.IntervalTimer`

Represents a scheduled callback inserted into the window timer registry.

- Fields: `id string`, `interval_ms int`, `running bool`, `one_shot bool`, `last_tick int`, `callback fn (mut win SimpleWindow)`
- Methods: `set_interval`, `set_timeout`, `add_timer`, `pause_timer`, `start_timer`, `reset_timer`, `stop_timer`, `is_timer_running`

#### `simplegui.TOMLWrapperDoc`

Convenience wrapper around `toml.parse_text` for quick config access.

- Methods: `get_string(key)`, `get_string_default(key, def)`, `get_int(key)`, `get_bool(key)`
- Factory: `toml_parse(content)`

#### `simplegui.SimpleWSClient`

Lightweight WebSocket wrapper for sending and closing text messages.

- Methods: `write_string(msg) !`, `close()`
- Factory: `websocket_client(url, on_msg)`

#### `simplegui.SimpleStopwatch`

High-precision timing helper for benchmarking and elapsed-time measurement.

- Methods: `elapsed_ms()`, `elapsed_sec()`, `restart()`, `stop()`
- Factory: `start_stopwatch()`

#### `simplegui.SimpleStack[T]`, `SimpleQueue[T]`, `SimpleSet[T]`, `SimpleRingBuffer[T]`

Generic collection wrappers around the V datatypes library.

- `SimpleStack[T]`: `push`, `pop`, `peek`, `len`, `is_empty`
- `SimpleQueue[T]`: `push`, `pop`, `peek`, `len`, `is_empty`
- `SimpleSet[T]`: `add`, `remove`, `exists`, `len`, `is_empty`, `to_array`
- `SimpleRingBuffer[T]`: `push`, `pop`, `len`, `capacity`, `is_empty`, `is_full`
- Factory helpers: `new_stack()`, `new_queue()`, `new_set()`, `new_ringbuffer(capacity)`

#### `simplegui.SimpleStringBuilder`

Growable string buffer for efficient concatenation.

- Methods: `write(text)`, `write_line(text)`, `str()`, `len()`
- Factory: `new_string_builder()`

#### `simplegui.SimpleBenchmark`

Benchmark helper that wraps V's `benchmark` package.

- Methods: `measure(label)`, `step()`, `ok()`, `fail()`, `step_message(label)`, `total_message(label)`, `stop()`
- Factory: `start_benchmark()`, `new_benchmark()`

#### `simplegui.SimpleTCPClient`, `SimpleUDPClient`, `SimpleUnixClient`

Simplified network clients for common socket protocols.

- `SimpleTCPClient`: `write(data) !`, `read() !string`, `close()`
- `SimpleUDPClient`: `write(data) !`, `read() !string`, `close()`
- `SimpleUnixClient`: `write(data) !`, `read() !string`, `close()`
- Factory functions: `tcp_connect(address)`, `udp_connect(address)`, `unix_connect(path)`

#### `simplegui.SimpleURL`

Parsed URL model used for URL construction and query serialization.

- Fields: `scheme string`, `host string`, `port string`, `path string`, `query map[string]string`, `fragment string`
- Methods: `build_url()`
- Factory: `url_parse(raw_url)`, `url_build(scheme, host, path, query_params)`

#### `simplegui.SimpleHTMLDocument`

HTML DOM wrapper for quick tag and attribute inspection.

- Methods: `get_tag_text(name)`, `get_tags_by_class(class_name)`, `get_attr(tag_name, attr_name)`, `get_all_links()`, `get_all_images()`, `strip_tags()`
- Factory: `html_parse(content)`

#### `simplegui.SimpleMinHeap[T]`

Min-priority queue wrapper around V's heap implementation.

- Methods: `push(item)`, `pop() !T`, `peek() !T`, `len()`
- Factory: `new_min_heap()`

#### `simplegui.SimpleBigInt`, `SimpleComplex`

Advanced numeric helper objects.

- `SimpleBigInt`: `add`, `sub`, `mul`, `div`, `mod`, `str()`; constructors `big_int_from_int`, `big_int_from_str`
- `SimpleComplex`: `add`, `sub`, `mul`, `div`, `abs()`, `arg()`, `conj()`, `exp()`, `str()`; constructor `complex_new(re, im)`

#### `simplegui.SimpleMutex`, `SimpleWaitGroup`

Thread synchronization wrappers.

- `SimpleMutex`: `lock()`, `unlock()`; constructor `new_mutex()`
- `SimpleWaitGroup`: `add(delta)`, `done()`, `wait()`; constructor `new_wait_group()`

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
