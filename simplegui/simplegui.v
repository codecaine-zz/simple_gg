// Module simplegui - Core UI Framework for V
// File: simplegui.v
//
// Description:
//   This file serves as the main entry point and core controller for SimpleGUI.
//   It defines `SimpleWindow`, which manages window lifecycle, UI controls registry, active theme,
//   reactive state store, overlays (modals, toasts, context menus, command palette), event listeners,
//   and widget factory methods (`add_button`, `add_textbox`, `add_slider`, `add_data_table`, etc.).

module simplegui

import gg
import math
import os
import time

// IntervalTimer represents a background scheduled interval or timeout timer callback.
@[heap]
pub struct IntervalTimer {
pub mut:
	id          string
	interval_ms int
	running     bool = true
	one_shot    bool
	last_tick   i64
	callback    fn (mut win SimpleWindow) = unsafe { nil }
}

// SimpleWindow represents a top-level desktop GUI window instance.
// It stores all registered UI controls, mouse/keyboard states, active theme colors,
// reactive state key-values, and event callback handlers.
@[heap]
pub struct SimpleWindow {
pub mut:
	gg_ctx                 &gg.Context = unsafe { nil } // Pointer to native V gg rendering graphics context
	title                  string // Main title text displayed in operating system window titlebar
	width                  int    // Current window width in pixels
	height                 int    // Current window height in pixels
	padding                int  = 16 // Default edge padding around window content in pixels
	spacing                int  = 10 // Default vertical spacing gap between controls in pixels
	responsive_layout      bool = true // Automatically recalculates control positions on window resize
	theme                  Theme  // Active color palette theme configuration (defaults to Apple Light)
	controls               []&Control // Sequential ordered list of all registered UI controls
	control_map            map[string]&Control // Fast dictionary lookup map by control name/ID
	focused_control        string // Name of the control currently receiving keyboard input focus
	hovered_control        string // Name of the control currently under mouse pointer
	mouse_x                f32    // Current mouse pointer X coordinate
	mouse_y                f32    // Current mouse pointer Y coordinate
	mouse_down             bool   // Mouse left-click button held state
	debug_mode             bool   // Print verbose diagnostic system logs to console
	always_on_top          bool   // Keep window layered above all other desktop applications
	opacity                f64  = 1.0 // Window transparency opacity (1.0 = fully opaque)
	min_width              int  = 200 // Minimum allowed window width during resize
	min_height             int  = 150 // Minimum allowed window height during resize
	max_width              int  = 4000 // Maximum allowed window width
	max_height             int  = 3000 // Maximum allowed window height
	resizable              bool = true // Allow user window resizing
	minimizable            bool = true // Show minimize titlebar button
	maximizable            bool = true // Show maximize titlebar button
	closeable              bool = true // Show close titlebar button
	titlebar_visible       bool = true // Render native OS titlebar
	subtitle               string // Optional secondary subtitle header text
	cursor_name            string = 'arrow' // Current mouse cursor icon ('arrow', 'hand', 'ibeam')
	cursor_stack           []string // Stack for pushing/popping temporary cursor states
	status_text            string   // Text message displayed in bottom window status bar
	close_shortcut_enabled bool = true // Close window on Cmd+W / Ctrl+W shortcut
	toast_title            string
	toast_message          string
	toast_timer            f64
	toasts                 []Toast // List of active notification toast popups on screen
	command_palette_active bool    // Spotlight / Command Palette overlay visibility (Ctrl+K / Cmd+K)
	command_palette_query  string  // Command Palette search filter query text
	command_palette_items  []CommandItem // Command items registered in palette
	command_palette_sel    int     // Selected index in Command Palette list
	context_menu_active    bool    // Right-click context menu overlay visibility
	context_menu_x         f32     // Context menu popup X coordinate
	context_menu_y         f32     // Context menu popup Y coordinate
	context_menu_items     []ContextMenuItem // Right-click context menu item list
	active_tab_map         map[string]int    // Map tracking selected tab index for container tabs
	// Window-level event callback handlers
	on_key_down_cb  fn (mut win SimpleWindow, key gg.KeyCode) = unsafe { nil } // Triggered when key pressed
	on_close_cb     fn (mut win SimpleWindow) bool            = unsafe { nil } // Triggered on close request
	on_submit_cb    VoidEventCallback                         = unsafe { nil } // Triggered on form submission
	on_resize_cb    fn (mut win SimpleWindow, w int, h int)   = unsafe { nil } // Triggered on window resize
	auto_id_counter int // Auto-increment counter for generating unique control IDs
	state_store     map[string]string // Reactive key-value state store dictionary
	state_listeners map[string][]StringEventCallback // Reactive listener callbacks for state keys
	fullscreen      bool // Fullscreen borderless display state
	// Modal Dialog Overlay State
	modal_active      bool   // Modal confirm dialog popup visibility
	modal_title       string // Modal dialog headline text
	modal_message     string // Modal dialog message body text
	modal_confirm_txt string = 'OK'     // Confirm button text label
	modal_cancel_txt  string = 'Cancel' // Cancel button text label
	modal_on_confirm  VoidEventCallback = unsafe { nil } // Callback when confirm button clicked
	modal_on_cancel   VoidEventCallback = unsafe { nil } // Callback when cancel button clicked
	timers            map[string]&IntervalTimer // Map of scheduled interval and timeout timers
	font_path         string // Custom font file path override (defaults to auto-detected system TTF on Linux)
	is_selecting_text  bool   // Mouse drag text selection active flag
	text_select_anchor int    // Mouse drag initial caret anchor index
}

// new_simple_window creates and initializes a new `SimpleWindow` instance with specified title, width, and height.
pub fn new_simple_window(title string, width int, height int) &SimpleWindow {
	mut win := &SimpleWindow{
		title:  title
		width:  width
		height: height
		theme:  get_theme('Apple Light')
		timers: map[string]&IntervalTimer{}
	}
	return win
}

// new_window is an alias for `new_simple_window`.
pub fn new_window(title string, width int, height int) &SimpleWindow {
	return new_simple_window(title, width, height)
}

// gen_id generates a unique control ID name string using an internal counter.
fn (mut win SimpleWindow) gen_id(prefix string) string {
	win.auto_id_counter++
	return '${prefix}_${win.auto_id_counter}'
}

// add_control registers a `Control` struct in the window and returns a pointer to the control for method chaining.
pub fn (mut win SimpleWindow) add_control(ctrl Control) &SimpleWindow {
	mut c := &Control{
		...ctrl
	}
	if c.name.len == 0 {
		c.name = win.gen_id(c.kind)
	}
	if c.kind in ['button', 'action'] && c.title.len > 0 {
		min_req_w := f32(c.title.len * 8 + 32)
		if min_req_w > c.w {
			c.w = min_req_w
		}
	}
	win.controls << c
	win.control_map[c.name] = c
	return win
}

pub fn (win &SimpleWindow) has_control(name string) bool {
	return name in win.control_map
}

pub fn (win &SimpleWindow) list_controls() []string {
	mut names := []string{}
	for k, _ in win.control_map {
		names << k
	}
	return names
}

pub fn (win &SimpleWindow) get_control_kind(name string) string {
	if ctrl := win.control_map[name] {
		return ctrl.kind
	}
	return ''
}

pub fn (win &SimpleWindow) require_control(name string) string {
	if name in win.control_map {
		return name
	}
	panic('Control not found: ${name}')
}

pub fn (mut win SimpleWindow) get_control_ptr(name string) !&Control {
	if ctrl := win.control_map[name] {
		return ctrl
	}
	return error('Control not found: ${name}')
}

pub fn (mut win SimpleWindow) control(name string) &Control {
	if ctrl := win.control_map[name] {
		return ctrl
	}
	panic('Control not found: ${name}')
}

// Window Operations & Builder Setters

pub fn (win &SimpleWindow) get_title() string {
	return win.title
}

pub fn (mut win SimpleWindow) set_title(title string) &SimpleWindow {
	win.title = title
	return win
}

pub fn (mut win SimpleWindow) set_window_title(title string) &SimpleWindow {
	return win.set_title(title)
}

pub fn (mut win SimpleWindow) set_debug_mode(enabled bool) &SimpleWindow {
	win.debug_mode = enabled
	return win
}

pub fn (win &SimpleWindow) get_debug_mode() bool {
	return win.debug_mode
}

pub fn (mut win SimpleWindow) set_always_on_top(enabled bool) &SimpleWindow {
	win.always_on_top = enabled
	return win
}

pub fn (win &SimpleWindow) get_always_on_top() bool {
	return win.always_on_top
}

pub fn (mut win SimpleWindow) set_topmost(enabled bool) &SimpleWindow {
	return win.set_always_on_top(enabled)
}

pub fn (win &SimpleWindow) is_topmost() bool {
	return win.get_always_on_top()
}

pub fn (mut win SimpleWindow) set_background_color(hex_color string) &SimpleWindow {
	win.theme.background_color = hex_color
	return win
}

pub fn (mut win SimpleWindow) set_font_color(color string) &SimpleWindow {
	win.theme.font_color = color
	return win
}

pub fn (mut win SimpleWindow) apply_theme(t Theme) &SimpleWindow {
	win.theme = t
	return win
}

pub fn (mut win SimpleWindow) set_theme(theme_name string) &SimpleWindow {
	win.theme = get_theme(theme_name)
	return win
}

pub fn (mut win SimpleWindow) set_padding(padding int) &SimpleWindow {
	win.padding = padding
	return win
}

pub fn (win &SimpleWindow) get_padding() int {
	return win.padding
}

pub fn (mut win SimpleWindow) set_spacing(spacing int) &SimpleWindow {
	win.spacing = spacing
	return win
}

pub fn (win &SimpleWindow) get_spacing() int {
	return win.spacing
}

pub fn (mut win SimpleWindow) set_responsive_layout(enabled bool) &SimpleWindow {
	win.responsive_layout = enabled
	return win
}

pub fn (win &SimpleWindow) get_responsive_layout() bool {
	return win.responsive_layout
}

pub fn (mut win SimpleWindow) set_min_size(w int, h int) &SimpleWindow {
	win.min_width = w
	win.min_height = h
	return win
}

pub fn (win &SimpleWindow) get_min_size() (int, int) {
	return win.min_width, win.min_height
}

pub fn (mut win SimpleWindow) set_max_size(w int, h int) &SimpleWindow {
	win.max_width = w
	win.max_height = h
	return win
}

pub fn (win &SimpleWindow) get_max_size() (int, int) {
	return win.max_width, win.max_height
}

pub fn (mut win SimpleWindow) set_minimum_size(w int, h int) &SimpleWindow {
	return win.set_min_size(w, h)
}

pub fn (win &SimpleWindow) get_minimum_size() (int, int) {
	return win.get_min_size()
}

pub fn (mut win SimpleWindow) set_maximum_size(w int, h int) &SimpleWindow {
	return win.set_max_size(w, h)
}

pub fn (win &SimpleWindow) get_maximum_size() (int, int) {
	return win.get_max_size()
}

pub fn (mut win SimpleWindow) set_resizable(enabled bool) &SimpleWindow {
	win.resizable = enabled
	return win
}

pub fn (win &SimpleWindow) get_resizable() bool {
	return win.resizable
}

pub fn (mut win SimpleWindow) set_minimizable(enabled bool) &SimpleWindow {
	win.minimizable = enabled
	return win
}

pub fn (win &SimpleWindow) get_minimizable() bool {
	return win.minimizable
}

pub fn (mut win SimpleWindow) set_maximizable(enabled bool) &SimpleWindow {
	win.maximizable = enabled
	return win
}

pub fn (win &SimpleWindow) get_maximizable() bool {
	return win.maximizable
}

pub fn (mut win SimpleWindow) set_width(width int) &SimpleWindow {
	win.width = math.max(win.min_width, math.min(win.max_width, width))
	win.recalculate_layout()
	return win
}

pub fn (mut win SimpleWindow) set_height(height int) &SimpleWindow {
	win.height = math.max(win.min_height, math.min(win.max_height, height))
	win.recalculate_layout()
	return win
}

pub fn (mut win SimpleWindow) set_size(width int, height int) &SimpleWindow {
	win.width = math.max(win.min_width, math.min(win.max_width, width))
	win.height = math.max(win.min_height, math.min(win.max_height, height))
	win.recalculate_layout()
	return win
}

pub fn (mut win SimpleWindow) resize(width int, height int) &SimpleWindow {
	return win.set_size(width, height)
}

pub fn (mut win SimpleWindow) fit_to_content() &SimpleWindow {
	win.recalculate_layout()
	mut max_x := f32(0.0)
	mut max_y := f32(0.0)
	for ctrl in win.controls {
		if ctrl.visible {
			right := ctrl.x + ctrl.w
			bottom := ctrl.y + ctrl.h
			if right > max_x {
				max_x = right
			}
			if bottom > max_y {
				max_y = bottom
			}
		}
	}
	pad := f32(win.padding)
	req_w := int(max_x + pad)
	req_h := int(max_y + pad)
	if req_w > win.width {
		win.width = math.max(win.min_width, math.min(win.max_width, req_w))
	}
	if req_h > win.height {
		win.height = math.max(win.min_height, math.min(win.max_height, req_h))
	}
	win.recalculate_layout()
	return win
}

pub fn (mut win SimpleWindow) fit_contents() &SimpleWindow {
	return win.fit_to_content()
}

pub fn (win &SimpleWindow) get_width() int {
	return win.width
}

pub fn (win &SimpleWindow) get_height() int {
	return win.height
}

pub fn (win &SimpleWindow) get_size() (int, int) {
	return win.width, win.height
}

pub fn (mut win SimpleWindow) set_position(x int, y int) &SimpleWindow {
	return win
}

pub fn (win &SimpleWindow) get_x() int {
	return 0
}

pub fn (win &SimpleWindow) get_y() int {
	return 0
}

pub fn (win &SimpleWindow) get_position() (int, int) {
	return 0, 0
}

pub fn (mut win SimpleWindow) set_bounds(x int, y int, w int, h int) &SimpleWindow {
	win.width = w
	win.height = h
	return win
}

pub fn (win &SimpleWindow) get_bounds() (int, int, int, int) {
	return 0, 0, win.width, win.height
}

pub fn (mut win SimpleWindow) set_opacity(opacity f64) &SimpleWindow {
	win.opacity = opacity
	return win
}

pub fn (win &SimpleWindow) get_opacity() f64 {
	return win.opacity
}

pub fn (mut win SimpleWindow) set_alpha(alpha f64) &SimpleWindow {
	return win.set_opacity(alpha)
}

pub fn (win &SimpleWindow) get_alpha() f64 {
	return win.get_opacity()
}

pub fn (mut win SimpleWindow) set_titlebar_visible(visible bool) &SimpleWindow {
	win.titlebar_visible = visible
	return win
}

pub fn (win &SimpleWindow) is_titlebar_visible() bool {
	return win.titlebar_visible
}

pub fn (mut win SimpleWindow) set_cursor(cursor_name string) &SimpleWindow {
	win.cursor_name = cursor_name
	return win
}

pub fn (win &SimpleWindow) get_cursor() string {
	return win.cursor_name
}

pub fn (mut win SimpleWindow) set_cursor_size(scale f64) &SimpleWindow {
	return win
}

pub fn (win &SimpleWindow) get_cursor_size() f64 {
	return 1.0
}

pub fn (mut win SimpleWindow) reset_cursor() &SimpleWindow {
	win.cursor_name = 'arrow'
	return win
}

pub fn (mut win SimpleWindow) push_cursor(cursor_name string) &SimpleWindow {
	win.cursor_stack << win.cursor_name
	win.cursor_name = cursor_name
	return win
}

pub fn (mut win SimpleWindow) pop_cursor() &SimpleWindow {
	if win.cursor_stack.len > 0 {
		win.cursor_name = win.cursor_stack.pop()
	}
	return win
}

pub fn (mut win SimpleWindow) set_control_cursor(control_name string, cursor_name string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(control_name) {
		ctrl.custom_cursor = cursor_name
	}
	return win
}

pub fn (win &SimpleWindow) get_mouse_location() (int, int) {
	return int(win.mouse_x), int(win.mouse_y)
}

pub fn (mut win SimpleWindow) move_cursor_to(x int, y int) &SimpleWindow {
	win.mouse_x = f32(x)
	win.mouse_y = f32(y)
	return win
}

pub fn (mut win SimpleWindow) set_fullscreen(enable bool) &SimpleWindow {
	win.fullscreen = enable
	return win
}

pub fn (mut win SimpleWindow) toggle_fullscreen() &SimpleWindow {
	win.fullscreen = !win.fullscreen
	return win
}

pub fn (mut win SimpleWindow) minimize() &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) deminimize() &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) maximize() &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) zoom() &SimpleWindow {
	return win
}

pub fn (win &SimpleWindow) is_minimized() bool {
	return false
}

pub fn (win &SimpleWindow) is_maximized() bool {
	return false
}

pub fn (win &SimpleWindow) is_fullscreen() bool {
	return win.fullscreen
}

pub fn (win &SimpleWindow) is_active() bool {
	return true
}

pub fn (mut win SimpleWindow) request_attention(critical bool) &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) bounce_dock(critical bool) &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) bounce_dock_icon(critical bool) &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) set_closable(enabled bool) &SimpleWindow {
	win.closeable = enabled
	return win
}

pub fn (win &SimpleWindow) get_closable() bool {
	return win.closeable
}

pub fn (mut win SimpleWindow) set_has_shadow(enabled bool) &SimpleWindow {
	return win
}

pub fn (win &SimpleWindow) get_has_shadow() bool {
	return true
}

pub fn (mut win SimpleWindow) set_movable_by_window_background(enabled bool) &SimpleWindow {
	return win
}

pub fn (win &SimpleWindow) get_movable_by_window_background() bool {
	return false
}

pub fn (win &SimpleWindow) is_visible() bool {
	return true
}

pub fn (mut win SimpleWindow) set_title_visible(visible bool) &SimpleWindow {
	return win
}

pub fn (win &SimpleWindow) get_title_visible() bool {
	return true
}

pub fn (win &SimpleWindow) is_title_visible() bool {
	return true
}

pub fn (mut win SimpleWindow) set_subtitle(subtitle string) &SimpleWindow {
	win.subtitle = subtitle
	return win
}

pub fn (win &SimpleWindow) get_subtitle() string {
	return win.subtitle
}

pub fn (mut win SimpleWindow) set_dark_theme(dark bool) &SimpleWindow {
	if dark {
		win.set_theme('Apple Dark')
	} else {
		win.set_theme('Apple Light')
	}
	return win
}

pub fn (mut win SimpleWindow) toggle_window_theme() &SimpleWindow {
	if win.theme.is_dark {
		win.set_theme('Apple Light')
	} else {
		win.set_theme('Apple Dark')
	}
	return win
}

pub fn (win &SimpleWindow) is_dark_theme() bool {
	return win.theme.is_dark
}

pub fn (mut win SimpleWindow) shake_window() &SimpleWindow {
	win.status_text = 'Shake feedback triggered'
	return win
}

pub fn (mut win SimpleWindow) shake_on_error() &SimpleWindow {
	return win.shake_window()
}

pub fn (mut win SimpleWindow) flash_and_shake() &SimpleWindow {
	return win.shake_window()
}

pub fn (mut win SimpleWindow) attention() &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) set_fixed_size(w int, h int) &SimpleWindow {
	win.set_size(w, h)
	win.set_min_size(w, h)
	win.set_max_size(w, h)
	win.set_resizable(false)
	return win
}

pub fn (mut win SimpleWindow) set_size_preset(preset string) &SimpleWindow {
	match preset {
		'small', 'compact' { win.set_size(400, 300) }
		'medium', 'standard' { win.set_size(640, 480) }
		'large' { win.set_size(800, 600) }
		'xlarge', 'xl' { win.set_size(1024, 768) }
		'hd', '720p' { win.set_size(1280, 720) }
		'full_hd', '1080p' { win.set_size(1920, 1080) }
		'dialog', 'alert' { win.set_size(420, 220) }
		'login', 'auth' { win.set_size(380, 450) }
		'settings', 'preferences' { win.set_size(550, 400) }
		'sidebar', 'panel' { win.set_size(300, 600) }
		'splash' { win.set_size(500, 300) }
		'square' { win.set_size(500, 500) }
		else { win.set_size(640, 480) }
	}
	return win
}

pub fn (mut win SimpleWindow) set_preset_size(preset string) &SimpleWindow {
	return win.set_size_preset(preset)
}

pub fn (mut win SimpleWindow) make_fixed_dialog(title string, w int, h int) &SimpleWindow {
	win.set_title(title)
	win.set_fixed_size(w, h)
	return win
}

pub fn (mut win SimpleWindow) make_splash_screen(w int, h int) &SimpleWindow {
	win.set_titlebar_visible(false)
	win.set_fixed_size(w, h)
	return win
}

pub fn (mut win SimpleWindow) make_utility_panel() &SimpleWindow {
	win.set_always_on_top(true)
	return win
}

pub fn (mut win SimpleWindow) make_frameless() &SimpleWindow {
	win.set_titlebar_visible(false)
	return win
}

pub fn (mut win SimpleWindow) make_always_on_top(enabled bool) &SimpleWindow {
	return win.set_always_on_top(enabled)
}

pub fn (mut win SimpleWindow) make_modal() &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) make_translucent(alpha f64) &SimpleWindow {
	return win.set_opacity(alpha)
}

pub fn (mut win SimpleWindow) center() &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) center_window() &SimpleWindow {
	return win.center()
}

pub fn (mut win SimpleWindow) recenter() &SimpleWindow {
	return win.center()
}

pub fn (mut win SimpleWindow) center_on_screen() &SimpleWindow {
	return win.center()
}

pub fn (mut win SimpleWindow) center_and_focus() &SimpleWindow {
	return win.center()
}

pub fn (mut win SimpleWindow) align(pos string) &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) align_window(pos string) &SimpleWindow {
	return win.align(pos)
}

pub fn (mut win SimpleWindow) close() &SimpleWindow {
	if win.gg_ctx != unsafe { nil } {
		win.gg_ctx.quit()
	}
	return win
}

pub fn (mut win SimpleWindow) close_window() &SimpleWindow {
	return win.close()
}

pub fn (mut win SimpleWindow) hide() &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) hide_window() &SimpleWindow {
	return win.hide()
}

pub fn (mut win SimpleWindow) show() &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) restore() &SimpleWindow {
	return win
}

pub fn (mut win SimpleWindow) restore_window() &SimpleWindow {
	return win.restore()
}

// Control Layout & Containers

pub fn (mut win SimpleWindow) begin_row(name string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'row_start' })
	return win
}

pub fn (mut win SimpleWindow) end_row() &SimpleWindow {
	win.add_control(Control{ kind: 'row_end' })
	return win
}

pub fn (mut win SimpleWindow) row(name string, callback VoidEventCallback) &SimpleWindow {
	win.begin_row(name)
	callback(mut win)
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) begin_grid(name string, columns int, spacing int) &SimpleWindow {
	win.add_control(Control{
		name:      name
		kind:      'grid_start'
		int_value: columns
		f64_value: f64(spacing)
	})
	return win
}

pub fn (mut win SimpleWindow) end_grid() &SimpleWindow {
	win.add_control(Control{ kind: 'grid_end' })
	return win
}

pub fn (mut win SimpleWindow) grid(name string, columns int, spacing int, callback VoidEventCallback) &SimpleWindow {
	win.begin_grid(name, columns, spacing)
	callback(mut win)
	win.end_grid()
	return win
}

pub fn (mut win SimpleWindow) begin_flex_box(name string, direction string, justify string, align string) &SimpleWindow {
	win.add_control(Control{
		name:        name
		kind:        'flex_start'
		title:       direction
		placeholder: justify
		alignment:   align
	})
	return win
}

pub fn (mut win SimpleWindow) end_flex_box() &SimpleWindow {
	win.add_control(Control{ kind: 'flex_end' })
	return win
}

pub fn (mut win SimpleWindow) flex_box(name string, direction string, justify string, align string, callback VoidEventCallback) &SimpleWindow {
	win.begin_flex_box(name, direction, justify, align)
	callback(mut win)
	win.end_flex_box()
	return win
}

pub fn (mut win SimpleWindow) add_group_box(name string, title string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'group_start', title: title })
	return win
}

pub fn (mut win SimpleWindow) add_group_box_with_options(name string, title string, border bool) &SimpleWindow {
	return win.add_group_box(name, title)
}

pub fn (mut win SimpleWindow) group(name string, title string, callback VoidEventCallback) &SimpleWindow {
	win.add_group_box(name, title)
	callback(mut win)
	win.add_control(Control{ kind: 'group_end' })
	return win
}

pub fn (mut win SimpleWindow) group_with_options(name string, title string, border bool, callback VoidEventCallback) &SimpleWindow {
	return win.group(name, title, callback)
}

pub fn (mut win SimpleWindow) group_config(name string, cfg GroupConfig, callback VoidEventCallback) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'group_start', title: cfg.title, group_cfg: cfg })
	callback(mut win)
	win.add_control(Control{ kind: 'group_end' })
	return win
}

pub fn (mut win SimpleWindow) card(name string, callback VoidEventCallback) &SimpleWindow {
	return win.group(name, '', callback)
}

pub fn (mut win SimpleWindow) card_with_title(name string, title string, callback VoidEventCallback) &SimpleWindow {
	return win.group(name, title, callback)
}

pub fn (mut win SimpleWindow) add_tabs(name string, titles []string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'tabs', items: titles, h: 32 })
	return win
}

pub fn (mut win SimpleWindow) add_scroll_view(name string, height int) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'scroll_view', h: f32(height) })
	return win
}

pub fn (mut win SimpleWindow) align_left() &SimpleWindow {
	if win.controls.len > 0 {
		win.controls.last().alignment = 'left'
	}
	return win
}

pub fn (mut win SimpleWindow) align_center() &SimpleWindow {
	if win.controls.len > 0 {
		win.controls.last().alignment = 'center'
	}
	return win
}

pub fn (mut win SimpleWindow) align_right() &SimpleWindow {
	if win.controls.len > 0 {
		win.controls.last().alignment = 'right'
	}
	return win
}

pub fn (mut win SimpleWindow) expand_fill() &SimpleWindow {
	if win.controls.len > 0 {
		win.controls.last().expand_fill = true
	}
	return win
}

pub fn (mut win SimpleWindow) add_action_row(actions map[string]VoidEventCallback) &SimpleWindow {
	win.begin_row(win.gen_id('action_row'))
	for title, cb in actions {
		btn_id := win.gen_id('act_btn')
		win.add_button(btn_id, title)
		win.on_click(btn_id, cb)
	}
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_fields_row(fields map[string]string) &SimpleWindow {
	win.begin_row(win.gen_id('fields_row'))
	for label, name in fields {
		win.add_form_field(label, name, '')
	}
	win.end_row()
	return win
}

// Adding Controls Widgets

pub fn (mut win SimpleWindow) add_label(name string, text string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'label', title: text, h: 24 })
	return win
}

pub fn (mut win SimpleWindow) add_heading(title string) &SimpleWindow {
	win.add_control(Control{ kind: 'heading', title: title, h: 36 })
	return win
}

pub fn (mut win SimpleWindow) add_subheading(title string) &SimpleWindow {
	win.add_control(Control{ kind: 'label', title: title, font_size: 14, h: 22 })
	return win
}

pub fn (mut win SimpleWindow) add_input(name string, value string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'input', text_value: value, h: 32 })
	return win
}

pub fn (mut win SimpleWindow) add_password(name string, value string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'password', text_value: value, h: 32 })
	return win
}

pub fn (mut win SimpleWindow) add_textarea(name string, value string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'textarea', text_value: value, h: 90 })
	return win
}

pub fn (mut win SimpleWindow) add_button(name string, title string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'button', title: title, h: 34 })
	return win
}

pub fn (mut win SimpleWindow) add_action(name string, title string, callback VoidEventCallback) &SimpleWindow {
	win.add_button(name, title)
	win.on_click(name, callback)
	return win
}

pub fn (mut win SimpleWindow) add_checkbox(name string, label string, checked bool) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'checkbox', title: label, bool_value: checked, h: 28 })
	return win
}

pub fn (mut win SimpleWindow) add_toggle(name string, label string, checked bool) &SimpleWindow {
	return win.add_checkbox(name, label, checked)
}

pub fn (mut win SimpleWindow) add_switch(name string, label string, checked bool) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'switch', title: label, bool_value: checked, h: 28 })
	return win
}

pub fn (mut win SimpleWindow) add_number(name string, value int) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'number', int_value: value, h: 32 })
	return win
}

pub fn (mut win SimpleWindow) add_number_field(name string, value int) &SimpleWindow {
	return win.add_number(name, value)
}

pub fn (mut win SimpleWindow) add_slider(name string, value int) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'slider', int_value: value, h: 28 })
	return win
}

pub fn (mut win SimpleWindow) add_dropdown(name string, items []string, selected string) &SimpleWindow {
	win.add_control(Control{
		name:       name
		kind:       'dropdown'
		items:      items
		text_value: selected
		h:          32
	})
	return win
}

pub fn (mut win SimpleWindow) add_segmented_control(name string, items []string, selected string) &SimpleWindow {
	win.add_control(Control{
		name:       name
		kind:       'segmented'
		items:      items
		text_value: selected
		h:          32
	})
	return win
}

pub fn (mut win SimpleWindow) add_radio_group(name string, items []string, selected string) &SimpleWindow {
	win.add_control(Control{
		name:       name
		kind:       'radio'
		items:      items
		text_value: selected
		h:          32
	})
	return win
}

pub fn (mut win SimpleWindow) add_progress_indicator(name string, value int) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'progress', int_value: value, h: 24 })
	return win
}

pub fn (mut win SimpleWindow) add_progress_bar(name string, value int) &SimpleWindow {
	return win.add_progress_indicator(name, value)
}

pub fn (mut win SimpleWindow) add_progress(name string, value int) &SimpleWindow {
	return win.add_progress_indicator(name, value)
}

pub fn (mut win SimpleWindow) add_date_picker(name string, date string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'date_picker', text_value: date, h: 32 })
	return win
}

pub fn (mut win SimpleWindow) add_color_well(name string, hex_color string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'color_well', text_value: hex_color, h: 32 })
	return win
}

pub fn (mut win SimpleWindow) add_mode_control(name string, selected string) &SimpleWindow {
	return win.add_segmented_control(name, ['Simple', 'Advanced', 'Expert'], selected)
}

pub fn (mut win SimpleWindow) add_list_box(name string, items []string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'list_box', items: items, h: 120 })
	return win
}

pub fn (mut win SimpleWindow) add_list_box_with_selected(name string, items []string, selected string) &SimpleWindow {
	sel_idx := items.index(selected)
	win.add_control(Control{
		name:       name
		kind:       'list_box'
		items:      items
		text_value: selected
		int_value:  if sel_idx >= 0 { sel_idx } else { 0 }
		h:          120
	})
	return win
}

pub fn (win &SimpleWindow) get_list_box_selected(name string) string {
	if ctrl := win.control_map[name] {
		return ctrl.text_value
	}
	return ''
}

pub fn (win &SimpleWindow) get_list_box_index(name string) int {
	if ctrl := win.control_map[name] {
		return ctrl.int_value
	}
	return 0
}

pub fn (mut win SimpleWindow) set_list_box_selected(name string, selected string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.text_value = selected
		sel_idx := ctrl.items.index(selected)
		if sel_idx >= 0 {
			ctrl.int_value = sel_idx
		}
	}
	return win
}

pub fn (mut win SimpleWindow) set_list_box_index(name string, index int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		if index >= 0 && index < ctrl.items.len {
			ctrl.int_value = index
			ctrl.text_value = ctrl.items[index]
		}
	}
	return win
}

pub fn (mut win SimpleWindow) add_multi_list_box(name string, items []string, selected []string) &SimpleWindow {
	win.add_control(Control{
		name:           name
		kind:           'multi_list_box'
		items:          items
		items_selected: selected
		h:              140
	})
	return win
}

pub fn (win &SimpleWindow) get_multi_list_box_selected(name string) []string {
	if ctrl := win.control_map[name] {
		return ctrl.items_selected
	}
	return []string{}
}

pub fn (mut win SimpleWindow) set_multi_list_box_selected(name string, selected []string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.items_selected = selected
	}
	return win
}

pub fn (mut win SimpleWindow) add_combobox(name string, items []string, selected string) &SimpleWindow {
	win.add_control(Control{
		name:       name
		kind:       'combobox'
		items:      items
		text_value: selected
		h:          32
	})
	return win
}

pub fn (win &SimpleWindow) get_combobox_selected(name string) string {
	if ctrl := win.control_map[name] {
		return ctrl.text_value
	}
	return ''
}

pub fn (mut win SimpleWindow) set_combobox_selected(name string, selected string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.text_value = selected
	}
	return win
}

pub fn (mut win SimpleWindow) add_color_palette(name string, hex_colors []string, selected string) &SimpleWindow {
	win.add_control(Control{
		name:       name
		kind:       'color_palette'
		items:      hex_colors
		text_value: selected
		h:          40
	})
	return win
}

pub fn (win &SimpleWindow) get_color_selected(name string) string {
	if ctrl := win.control_map[name] {
		return ctrl.text_value
	}
	return ''
}

pub fn (mut win SimpleWindow) set_color_selected(name string, hex_color string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.text_value = hex_color
	}
	return win
}

pub fn (mut win SimpleWindow) add_status_bar(name string, status_text string, badge string) &SimpleWindow {
	win.add_control(Control{
		name:        name
		kind:        'status_bar'
		text_value:  status_text
		placeholder: badge
		h:           26
	})
	return win
}

pub fn (mut win SimpleWindow) set_status_bar_text(name string, status_text string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.text_value = status_text
	}
	return win
}

pub fn (mut win SimpleWindow) add_step_slider(name string, steps int, value f64) &SimpleWindow {
	win.add_control(Control{
		name:      name
		kind:      'step_slider'
		int_value: steps
		f64_value: value
		h:         34
	})
	return win
}

pub fn (win &SimpleWindow) get_step_slider_value(name string) f64 {
	if ctrl := win.control_map[name] {
		return ctrl.f64_value
	}
	return 0.0
}

pub fn (mut win SimpleWindow) set_step_slider_value(name string, value f64) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.f64_value = value
	}
	return win
}

pub fn (mut win SimpleWindow) add_transfer_list(name string, available []string, selected []string) &SimpleWindow {
	win.add_control(Control{
		name:           name
		kind:           'transfer_list'
		items:          available
		items_selected: selected
		h:              130
		w:              340
	})
	return win
}

pub fn (win &SimpleWindow) get_transfer_list_selected(name string) []string {
	if ctrl := win.control_map[name] {
		return ctrl.items_selected
	}
	return []string{}
}

pub fn (win &SimpleWindow) get_transfer_list_available(name string) []string {
	if ctrl := win.control_map[name] {
		return ctrl.items
	}
	return []string{}
}

pub fn (mut win SimpleWindow) add_console_view(name string, initial_logs []string) &SimpleWindow {
	win.add_control(Control{
		name:  name
		kind:  'console_view'
		items: initial_logs
		h:     140
		w:     340
	})
	return win
}

pub fn (mut win SimpleWindow) append_console_log(name string, log_msg string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.items << log_msg
	}
	return win
}

pub fn (mut win SimpleWindow) clear_console_log(name string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.items.clear()
	}
	return win
}

pub fn (mut win SimpleWindow) add_image(name string, file_path string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'image', text_value: file_path, h: 100 })
	return win
}

pub fn (mut win SimpleWindow) add_search_field(name string, placeholder string) &SimpleWindow {
	win.add_control(Control{
		name:        name
		kind:        'search_field'
		placeholder: placeholder
		h:           32
	})
	return win
}

pub fn (mut win SimpleWindow) add_rating(name string, value int) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'rating', int_value: value, h: 28 })
	return win
}

pub fn (mut win SimpleWindow) add_spinner(name string, active bool) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'spinner', bool_value: active, h: 24 })
	return win
}

pub fn (mut win SimpleWindow) add_grid(name string, headers []string, initial_rows [][]string) &SimpleWindow {
	win.add_control(Control{
		name:    name
		kind:    'grid'
		headers: headers
		rows:    initial_rows
		h:       150
	})
	return win
}

pub fn (mut win SimpleWindow) add_chart(name string, chart_type string, height int) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'chart', title: chart_type, h: f32(height) })
	return win
}

pub fn (mut win SimpleWindow) set_chart_data(name string, values []f64) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.f64_list = values
	}
	return win
}

pub fn (mut win SimpleWindow) add_metric_card(name string, title string, value string, change_badge string, subtitle string) &SimpleWindow {
	win.add_control(Control{
		name:        name
		kind:        'metric_card'
		title:       title
		text_value:  value
		placeholder: change_badge
		h:           64
	})
	return win
}

pub fn (mut win SimpleWindow) add_alert_banner(name string, title string, message string, style string) &SimpleWindow {
	win.add_control(Control{
		name:       name
		kind:       'alert_banner'
		title:      title
		text_value: message
		h:          40
	})
	return win
}

pub fn (mut win SimpleWindow) set_close_shortcut_enabled(enabled bool) &SimpleWindow {
	win.close_shortcut_enabled = enabled
	return win
}

pub fn (mut win SimpleWindow) on_close(cb fn (mut win SimpleWindow) bool) &SimpleWindow {
	win.on_close_cb = cb
	return win
}

pub fn (mut win SimpleWindow) show_toast(title string, message string) &SimpleWindow {
	win.toast_title = title
	win.toast_message = message
	win.toast_timer = 4.0
	win.toasts << Toast{
		id:          win.gen_id('toast')
		title:       title
		message:     message
		variant:     'info'
		duration_ms: 4000
	}
	return win
}

pub fn (mut win SimpleWindow) add_tree_view(name string, nodes []TreeNode) &SimpleWindow {
	win.add_control(Control{
		name:       name
		kind:       'tree_view'
		tree_nodes: nodes
		h:          f32(math.max(100, nodes.len * 26 + 10))
	})
	return win
}

pub fn (mut win SimpleWindow) add_table(name string, headers []string, rows [][]string) &SimpleWindow {
	win.add_control(Control{
		name:    name
		kind:    'table'
		headers: headers
		rows:    rows
		w:       420.0
		h:       f32(math.max(120, (rows.len + 1) * 28 + 10))
	})
	return win
}

pub fn (mut win SimpleWindow) on_row_click(name string, cb VoidEventCallback) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.on_row_click = cb
	}
	return win
}

pub fn (win &SimpleWindow) get_table_selected_row(name string) int {
	if ctrl := win.control_map[name] {
		return ctrl.selected_row
	}
	return -1
}

pub fn (mut win SimpleWindow) clear_table_selection(name string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.selected_row = -1
	}
	return win
}

pub fn (win &SimpleWindow) get_table_rows(name string) [][]string {
	if ctrl := win.control_map[name] {
		return ctrl.rows
	}
	return [][]string{}
}

pub fn (mut win SimpleWindow) set_table_rows(name string, rows [][]string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.rows = rows
		ctrl.selected_row = -1
		ctrl.scroll_offset_y = 0
		ctrl.h = f32(math.max(120, (rows.len + 1) * 28 + 10))
	}
	return win
}

pub fn (mut win SimpleWindow) add_table_row(name string, row []string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.rows << row
	}
	return win
}

pub fn (mut win SimpleWindow) remove_table_row(name string, index int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		if index >= 0 && index < ctrl.rows.len {
			ctrl.rows.delete(index)
			if ctrl.selected_row == index {
				ctrl.selected_row = -1
			}
		}
	}
	return win
}

// sort_table sorts rows by column_index; numeric cells are compared numerically, others alphabetically.
pub fn (mut win SimpleWindow) sort_table(name string, column_index int, ascending bool) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		if column_index >= 0 {
			sort_table_rows(ctrl, column_index, ascending)
			ctrl.sort_col = column_index
			ctrl.sort_asc = ascending
		}
	}
	return win
}

pub fn (win &SimpleWindow) get_table_sort(name string) (int, bool) {
	if ctrl := win.control_map[name] {
		return ctrl.sort_col, ctrl.sort_asc
	}
	return -1, true
}

// sort_table_rows performs an in-place insertion sort on ctrl.rows by the given column.
fn sort_table_rows(ctrl &Control, col_idx int, asc bool) {
	unsafe {
		mut ptr := &Control(ctrl)
		n := ptr.rows.len
		for i in 1 .. n {
			key := ptr.rows[i].clone()
			key_val := if col_idx < key.len { key[col_idx] } else { '' }
			mut j := i - 1
			for j >= 0 {
				cur_val := if col_idx < ptr.rows[j].len { ptr.rows[j][col_idx] } else { '' }
				should_swap := if asc {
					compare_table_cell(cur_val, key_val) > 0
				} else {
					compare_table_cell(cur_val, key_val) < 0
				}
				if !should_swap {
					break
				}
				ptr.rows[j + 1] = ptr.rows[j]
				j--
			}
			ptr.rows[j + 1] = key
		}
	}
}

// compare_table_cell compares two cell values numerically when both look like numbers, else alphabetically.
fn compare_table_cell(a string, b string) int {
	a_trim := a.trim_space()
	b_trim := b.trim_space()
	a_is_num := a_trim.len > 0
		&& (a_trim[0].is_digit() || (a_trim[0] == `-` && a_trim.len > 1 && a_trim[1].is_digit()))
	b_is_num := b_trim.len > 0
		&& (b_trim[0].is_digit() || (b_trim[0] == `-` && b_trim.len > 1 && b_trim[1].is_digit()))
	if a_is_num && b_is_num {
		a_num := a_trim.f64()
		b_num := b_trim.f64()
		if a_num < b_num {
			return -1
		}
		if a_num > b_num {
			return 1
		}
		return 0
	}
	if a_trim < b_trim {
		return -1
	}
	if a_trim > b_trim {
		return 1
	}
	return 0
}

pub fn (mut win SimpleWindow) begin_tab_container(name string, titles []string) &SimpleWindow {
	win.add_control(Control{
		name:      name
		kind:      'tab_container_start'
		items:     titles
		int_value: 0
	})
	return win
}

pub fn (mut win SimpleWindow) end_tab_container() &SimpleWindow {
	win.add_control(Control{ kind: 'tab_container_end' })
	return win
}

pub fn (mut win SimpleWindow) begin_tab_page(name string, tab_index int) &SimpleWindow {
	win.add_control(Control{
		name:      name
		kind:      'tab_page_start'
		int_value: tab_index
	})
	return win
}

pub fn open_native_file_dialog() string {
	$if macos {
		res := os.execute("osascript -e 'POSIX path of (choose file)'")
		if res.exit_code == 0 {
			return res.output.trim_space()
		}
	} $else {
		res := os.execute('zenity --file-selection 2>/dev/null')
		if res.exit_code == 0 {
			return res.output.trim_space()
		}
	}
	return ''
}

pub fn (mut win SimpleWindow) end_tab_page() &SimpleWindow {
	win.add_control(Control{ kind: 'tab_page_end' })
	return win
}

pub fn (mut win SimpleWindow) add_file_picker(name string, label string, initial_path string) &SimpleWindow {
	win.add_control(Control{
		name:       name
		kind:       'file_picker'
		title:      label
		text_value: initial_path
		h:          34
	})
	return win
}

pub fn (mut win SimpleWindow) add_search_bar(name string, placeholder string) &SimpleWindow {
	win.add_control(Control{
		name:        name
		kind:        'search_bar'
		placeholder: placeholder
		h:           34
	})
	return win
}

pub fn (mut win SimpleWindow) add_badge(name string, text string, variant string) &SimpleWindow {
	win.add_control(Control{
		name:    name
		kind:    'badge'
		title:   text
		variant: variant
		h:       24
	})
	return win
}

pub fn (mut win SimpleWindow) add_breadcrumb(name string, items []string) &SimpleWindow {
	win.add_control(Control{
		name:  name
		kind:  'breadcrumb'
		items: items
		h:     24
	})
	return win
}

pub fn (mut win SimpleWindow) add_stepper(name string, steps []string, active_step int) &SimpleWindow {
	win.add_control(Control{
		name:      name
		kind:      'stepper'
		items:     steps
		int_value: active_step
		h:         40
	})
	return win
}

pub fn (mut win SimpleWindow) add_accordion(name string, title string, content string, expanded bool) &SimpleWindow {
	win.add_control(Control{
		name:        name
		kind:        'accordion'
		title:       title
		text_value:  content
		is_expanded: expanded
		h:           if expanded { f32(110.0) } else { f32(36.0) }
	})
	return win
}

pub fn (mut win SimpleWindow) add_avatar(name string, initials string, subtext string) &SimpleWindow {
	win.add_control(Control{
		name:        name
		kind:        'avatar'
		title:       initials
		placeholder: subtext
		h:           40
	})
	return win
}

pub fn (mut win SimpleWindow) add_divider(text string) &SimpleWindow {
	win.add_control(Control{
		kind:  'divider'
		title: text
		h:     20
	})
	return win
}

// Additional Developer & User-Requested Controls

pub fn (mut win SimpleWindow) add_icon_button(name string, icon string, tooltip string) &SimpleWindow {
	win.add_control(Control{
		name:    name
		kind:    'icon_button'
		title:   icon
		tooltip: tooltip
		w:       36
		h:       34
	})
	return win
}

pub fn (mut win SimpleWindow) add_toolbar(name string, items []ToolbarItem) &SimpleWindow {
	win.begin_row(name)
	for item in items {
		btn_id := win.gen_id('${name}_tool')
		win.add_icon_button(btn_id, item.icon, item.tooltip)
		win.set_control_width(btn_id, 36)
		if item.on_click != unsafe { nil } {
			win.on_click(btn_id, item.on_click)
		}
	}
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_link(name string, text string, url string) &SimpleWindow {
	win.add_control(Control{ name: name, kind: 'link', title: text, placeholder: url, h: 22 })
	win.on_click(name, fn [url] (mut win SimpleWindow) {
		win.open_url(url)
	})
	return win
}

pub fn (mut win SimpleWindow) add_checklist(name string, items []string, selected []string) &SimpleWindow {
	win.add_control(Control{
		name:           name
		kind:           'checklist'
		items:          items
		items_selected: selected
		h:              f32(math.max(60, items.len * 26 + 10))
	})
	return win
}

pub fn (win &SimpleWindow) get_checklist_selected(name string) []string {
	if ctrl := win.control_map[name] {
		return ctrl.items_selected
	}
	return []string{}
}

pub fn (mut win SimpleWindow) set_checklist_selected(name string, selected []string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.items_selected = selected
	}
	return win
}

pub fn (mut win SimpleWindow) add_chip_group(name string, items []string, selected []string) &SimpleWindow {
	win.add_control(Control{
		name:           name
		kind:           'chip_group'
		items:          items
		items_selected: selected
		h:              36
	})
	return win
}

pub fn (win &SimpleWindow) get_chip_selected(name string) []string {
	if ctrl := win.control_map[name] {
		return ctrl.items_selected
	}
	return []string{}
}

pub fn (mut win SimpleWindow) set_chip_selected(name string, selected []string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.items_selected = selected
	}
	return win
}

pub fn (mut win SimpleWindow) add_time_picker(name string, time_str string) &SimpleWindow {
	win.add_control(Control{
		name:        name
		kind:        'time_picker'
		text_value:  time_str
		placeholder: 'HH:MM'
		h:           32
	})
	return win
}

pub fn (mut win SimpleWindow) add_form_time_picker(label string, name string, time_str string) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_time_picker(name, time_str)
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_password_strength(name string, target_field string) &SimpleWindow {
	mut ctrl := Control{
		name: name
		kind: 'password_strength'
		h:    30
	}
	ctrl.props['target'] = target_field
	win.add_control(ctrl)
	return win
}

pub fn (mut win SimpleWindow) add_menu_button(name string, title string, items []string) &SimpleWindow {
	win.add_control(Control{
		name:  name
		kind:  'menu_button'
		title: title
		items: items
		h:     34
	})
	return win
}

pub fn (win &SimpleWindow) get_menu_selected(name string) string {
	if ctrl := win.control_map[name] {
		return ctrl.text_value
	}
	return ''
}

pub fn (mut win SimpleWindow) begin_split_view(name string, split_pct int) &SimpleWindow {
	win.add_control(Control{
		name:      name
		kind:      'split_start'
		int_value: split_pct
	})
	return win
}

pub fn (mut win SimpleWindow) end_split_view() &SimpleWindow {
	win.add_control(Control{ kind: 'split_end' })
	return win
}

pub fn (mut win SimpleWindow) add_form_search(label string, name string, placeholder string) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_search_bar(name, placeholder)
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_form_file_picker(label string, name string, initial_path string) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_file_picker(name, label, initial_path)
	win.end_row()
	return win
}

// Form Helpers (add_form_*)

pub fn (mut win SimpleWindow) add_form_field(label string, name string, value string) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_input(name, value)
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_form_textarea(label string, name string, value string) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.add_label(lbl_id, label)
	win.add_textarea(name, value)
	return win
}

pub fn (mut win SimpleWindow) add_form_password(label string, name string, value string) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_password(name, value)
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_form_slider(label string, name string, value int) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_slider(name, value)
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_form_number(label string, name string, value int) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_number(name, value)
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_form_dropdown(label string, name string, items []string, selected string) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_dropdown(name, items, selected)
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_form_list_box(label string, name string, items []string, selected string) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.add_label(lbl_id, label)
	win.add_list_box_with_selected(name, items, selected)
	return win
}

pub fn (mut win SimpleWindow) add_form_multi_list_box(label string, name string, items []string, selected []string) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.add_label(lbl_id, label)
	win.add_multi_list_box(name, items, selected)
	return win
}

pub fn (mut win SimpleWindow) add_form_combobox(label string, name string, items []string, selected string) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_combobox(name, items, selected)
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_form_date_picker(label string, name string, date string) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_date_picker(name, date)
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_form_progress(label string, name string, value int) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_progress_indicator(name, value)
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_form_switch(label string, name string, switch_label string, checked bool) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_switch(name, switch_label, checked)
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_form_checkbox(label string, name string, checkbox_label string, checked bool) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_checkbox(name, checkbox_label, checked)
	win.end_row()
	return win
}

pub fn (mut win SimpleWindow) add_form_link(label string, name string, link_text string, url string) &SimpleWindow {
	lbl_id := win.gen_id('lbl')
	win.begin_row(win.gen_id('form_row'))
	win.add_label(lbl_id, label)
	win.add_control(Control{ name: name, kind: 'link', title: link_text, placeholder: url, h: 24 })
	win.end_row()
	return win
}

// Nameless Shortcuts

pub fn (mut win SimpleWindow) input(value string) &SimpleWindow {
	return win.add_input('default_input', value)
}

pub fn (win &SimpleWindow) get_input() string {
	return win.get_text('default_input')
}

pub fn (mut win SimpleWindow) textarea(text string) &SimpleWindow {
	return win.add_textarea('default_textarea', text)
}

pub fn (win &SimpleWindow) get_textarea() string {
	return win.get_text('default_textarea')
}

pub fn (mut win SimpleWindow) checkbox(title string, checked bool) &SimpleWindow {
	return win.add_checkbox('default_checkbox', title, checked)
}

pub fn (win &SimpleWindow) get_checkbox() bool {
	return win.get_bool('default_checkbox')
}

pub fn (mut win SimpleWindow) number(value int) &SimpleWindow {
	return win.add_number('default_number', value)
}

pub fn (win &SimpleWindow) get_number() int {
	return win.get_value_int('default_number')
}

pub fn (mut win SimpleWindow) button(title string) &SimpleWindow {
	return win.add_button('default_button', title)
}

// Reading & Writing Values

// get_text retrieves the text value string for control `name`.
// Optional `default_val`: Allows specifying a custom fallback string returned if control `name` is not found (defaults to `""`).
// Example: `name := win.get_text('username_field', 'Guest')`
pub fn (win &SimpleWindow) get_text(name string, default_val ...string) string {
	fallback := if default_val.len > 0 { default_val[0] } else { '' }
	return win.get_text_or(name, fallback)
}

// get_text_or retrieves the text value string for control `name`, returning `fallback` if the control is not found.
pub fn (win &SimpleWindow) get_text_or(name string, fallback string) string {
	if ctrl := win.control_map[name] {
		if ctrl.kind in ['checkbox', 'switch', 'toggle'] {
			return ctrl.bool_value.str()
		}
		if ctrl.kind in ['slider', 'number', 'progress', 'stepper', 'rating', 'spinner'] {
			if ctrl.text_value.len > 0 {
				return ctrl.text_value
			}
			return ctrl.int_value.str()
		} else if ctrl.kind in ['step_slider', 'range_slider'] {
			if ctrl.text_value.len > 0 {
				return ctrl.text_value
			}
			return ctrl.f64_value.str()
		} else if ctrl.kind in ['dropdown', 'select', 'combobox'] {
			if ctrl.int_value >= 0 && ctrl.int_value < ctrl.items.len {
				return ctrl.items[ctrl.int_value]
			}
		}
		return ctrl.text_value
	}
	return fallback
}

// set_text sets the string text value for control `name`.
pub fn (mut win SimpleWindow) set_text(name string, value string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.text_value = value
		if ctrl.kind in ['label', 'heading', 'button', 'badge', 'link', 'tag'] {
			ctrl.title = value
		}
		if ctrl.kind in ['checkbox', 'switch', 'toggle'] {
			ctrl.bool_value = (value.to_lower().trim_space() in ['true', '1', 'yes', 'on'])
		} else if ctrl.kind in ['slider', 'number', 'progress', 'stepper', 'rating', 'spinner'] {
			ctrl.int_value = value.int()
		} else if ctrl.kind in ['step_slider', 'range_slider'] {
			ctrl.f64_value = value.f64()
		} else if ctrl.kind in ['dropdown', 'select', 'combobox'] {
			for idx, item in ctrl.items {
				if item == value {
					ctrl.int_value = idx
					break
				}
			}
		}
	}
	return win
}

// get_bool retrieves the boolean value for control `name` (e.g. CheckBox/Switch checked state).
// Optional `default_val`: Allows specifying a custom fallback boolean returned if control `name` is not found (defaults to `false`).
// Example: `checked := win.get_bool('subscribe_checkbox', true)`
pub fn (win &SimpleWindow) get_bool(name string, default_val ...bool) bool {
	fallback := if default_val.len > 0 { default_val[0] } else { false }
	return win.get_bool_or(name, fallback)
}

// get_bool_or retrieves the boolean value for control `name`, returning `fallback` if the control is not found.
pub fn (win &SimpleWindow) get_bool_or(name string, fallback bool) bool {
	if ctrl := win.control_map[name] {
		return ctrl.bool_value
	}
	return fallback
}

// set_bool sets the boolean state for control `name`.
pub fn (mut win SimpleWindow) set_bool(name string, value bool) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.bool_value = value
	}
	return win
}

// get_value_int retrieves the native integer value for control `name` (e.g. selected index or tab index).
// Optional `default_val`: Allows specifying a custom fallback integer returned if control `name` is not found (defaults to `0`).
// Example: `tab_idx := win.get_value_int('tab_bar', 0)`
pub fn (win &SimpleWindow) get_value_int(name string, default_val ...int) int {
	fallback := if default_val.len > 0 { default_val[0] } else { 0 }
	return win.get_value_int_or(name, fallback)
}

// get_value_int_or retrieves the native integer value for control `name`, returning `fallback` if the control is not found.
pub fn (win &SimpleWindow) get_value_int_or(name string, fallback int) int {
	if ctrl := win.control_map[name] {
		return ctrl.int_value
	}
	return fallback
}

// set_value_int sets the integer value for control `name`.
pub fn (mut win SimpleWindow) set_value_int(name string, value int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.int_value = value
	}
	return win
}

// get_value_f64 retrieves the 64-bit floating point value for control `name` (e.g. slider position).
// Optional `default_val`: Allows specifying a custom fallback float returned if control `name` is not found (defaults to `0.0`).
// Example: `pos := win.get_value_f64('slider', 50.0)`
pub fn (win &SimpleWindow) get_value_f64(name string, default_val ...f64) f64 {
	fallback := if default_val.len > 0 { default_val[0] } else { 0.0 }
	return win.get_value_f64_or(name, fallback)
}

// get_value_f64_or retrieves the 64-bit float value for control `name`, returning `fallback` if the control is not found.
pub fn (win &SimpleWindow) get_value_f64_or(name string, fallback f64) f64 {
	if ctrl := win.control_map[name] {
		return ctrl.f64_value
	}
	return fallback
}

// set_value_f64 sets the 64-bit floating point value for control `name`.
pub fn (mut win SimpleWindow) set_value_f64(name string, value f64) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.f64_value = value
	}
	return win
}

pub fn (mut win SimpleWindow) set_control_enabled(name string, enabled bool) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.disabled = !enabled
	}
	return win
}

pub fn (win &SimpleWindow) get_control_enabled(name string) bool {
	if ctrl := win.control_map[name] {
		return !ctrl.disabled
	}
	return true
}

pub fn (mut win SimpleWindow) set_control_visible(name string, visible bool) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.visible = visible
	}
	return win
}

pub fn (win &SimpleWindow) get_control_visible(name string) bool {
	if ctrl := win.control_map[name] {
		return ctrl.visible
	}
	return true
}

// Control Geometry & Size
pub fn (mut win SimpleWindow) set_control_width(name string, width int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.w = f32(width)
	}
	return win
}

pub fn (win &SimpleWindow) get_control_width(name string) int {
	if ctrl := win.control_map[name] {
		return int(ctrl.w)
	}
	return 0
}

pub fn (mut win SimpleWindow) set_control_height(name string, height int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.h = f32(height)
	}
	return win
}

pub fn (win &SimpleWindow) get_control_height(name string) int {
	if ctrl := win.control_map[name] {
		return int(ctrl.h)
	}
	return 0
}

pub fn (mut win SimpleWindow) set_control_size(name string, width int, height int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.w = f32(width)
		ctrl.h = f32(height)
	}
	return win
}

pub fn (mut win SimpleWindow) set_control_position(name string, x int, y int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.x = f32(x)
		ctrl.y = f32(y)
	}
	return win
}

// Control Spacing: Padding & Margin
pub fn (mut win SimpleWindow) set_control_padding(name string, padding int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.set_padding(padding)
	}
	return win
}

pub fn (win &SimpleWindow) get_control_padding(name string) int {
	if ctrl := win.control_map[name] {
		return int(ctrl.padding_left)
	}
	return 0
}

pub fn (mut win SimpleWindow) set_control_padding_xy(name string, px int, py int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.set_padding_xy(px, py)
	}
	return win
}

pub fn (mut win SimpleWindow) set_control_padding_trbl(name string, top int, right int, bottom int, left int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.set_padding_trbl(top, right, bottom, left)
	}
	return win
}

pub fn (mut win SimpleWindow) set_control_margin(name string, margin int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.set_margin(margin)
	}
	return win
}

pub fn (win &SimpleWindow) get_control_margin(name string) int {
	if ctrl := win.control_map[name] {
		return int(ctrl.margin_left)
	}
	return 0
}

pub fn (mut win SimpleWindow) set_control_margin_xy(name string, mx int, my int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.set_margin_xy(mx, my)
	}
	return win
}

pub fn (mut win SimpleWindow) set_control_margin_trbl(name string, top int, right int, bottom int, left int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.set_margin_trbl(top, right, bottom, left)
	}
	return win
}

// Layout & Alignment
pub fn (mut win SimpleWindow) set_control_alignment(name string, alignment string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.alignment = alignment
	}
	return win
}

pub fn (win &SimpleWindow) get_control_alignment(name string) string {
	if ctrl := win.control_map[name] {
		return ctrl.alignment
	}
	return ''
}

pub fn (mut win SimpleWindow) set_control_expand_fill(name string, expand bool) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.expand_fill = expand
	}
	return win
}

pub fn (win &SimpleWindow) get_control_expand_fill(name string) bool {
	if ctrl := win.control_map[name] {
		return ctrl.expand_fill
	}
	return false
}

// Typography & Font Customization
pub fn (mut win SimpleWindow) set_control_font_size(name string, size int) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.font_size = size
		if ctrl.h < f32(size + 6) {
			ctrl.h = f32(size + 6)
		}
	}
	win.recalculate_layout()
	return win
}

pub fn (win &SimpleWindow) get_control_font_size(name string) int {
	if ctrl := win.control_map[name] {
		return ctrl.font_size
	}
	return 0
}

pub fn (mut win SimpleWindow) set_control_font_bold(name string, bold bool) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.font_bold = bold
	}
	win.recalculate_layout()
	return win
}

pub fn (mut win SimpleWindow) set_control_font_name(name string, font_name string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.font_name = font_name
	}
	return win
}

// set_font_path configures custom TTF or OTF font file path for window text rendering.
pub fn (mut win SimpleWindow) set_font_path(path string) &SimpleWindow {
	win.font_path = path
	return win
}

pub fn (mut win SimpleWindow) set_control_placeholder(name string, placeholder string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.placeholder = placeholder
	}
	return win
}

pub fn (mut win SimpleWindow) set_control_text_align(name string, align string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.text_align = align
	}
	return win
}

// Colors, Borders & Opacity
pub fn (mut win SimpleWindow) set_control_bg_color(name string, color string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.bg_color = color
	}
	return win
}

pub fn (mut win SimpleWindow) set_control_background_color(name string, color string) &SimpleWindow {
	return win.set_control_bg_color(name, color)
}

pub fn (mut win SimpleWindow) set_control_font_color(name string, color string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.font_color = color
	}
	return win
}

pub fn (mut win SimpleWindow) set_control_accent_color(name string, color string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.accent_color = color
	}
	return win
}

pub fn (mut win SimpleWindow) set_control_border(name string, width f32, color string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.border_width = width
		ctrl.border_color = color
	}
	return win
}

pub fn (mut win SimpleWindow) set_control_corner_radius(name string, radius f32) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.corner_radius = radius
	}
	return win
}

pub fn (mut win SimpleWindow) set_control_opacity(name string, opacity f64) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.opacity = opacity
	}
	return win
}

// Tooltips
pub fn (mut win SimpleWindow) set_control_tooltip(name string, tooltip string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.tooltip = tooltip
	}
	return win
}

pub fn (win &SimpleWindow) get_control_tooltip(name string) string {
	if ctrl := win.control_map[name] {
		return ctrl.tooltip
	}
	return ''
}

// Event Bindings

pub fn (mut win SimpleWindow) on_click(name string, cb VoidEventCallback) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.on_click = cb
	}
	return win
}

pub fn (mut win SimpleWindow) on_change(name string, cb VoidEventCallback) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.on_change = cb
	}
	return win
}

pub fn (mut win SimpleWindow) on_enter(name string, cb VoidEventCallback) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.on_enter = cb
	}
	return win
}

pub fn (mut win SimpleWindow) on_hover(name string, cb VoidEventCallback) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.on_hover = cb
	}
	return win
}

pub fn (mut win SimpleWindow) on_dblclick(name string, cb VoidEventCallback) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.on_dblclick = cb
	}
	return win
}

pub fn (mut win SimpleWindow) on_double_click(name string, cb VoidEventCallback) &SimpleWindow {
	return win.on_dblclick(name, cb)
}

pub fn (mut win SimpleWindow) on_right_click(name string, cb VoidEventCallback) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.on_right_click = cb
	}
	return win
}

pub fn (mut win SimpleWindow) on_submit(cb VoidEventCallback) &SimpleWindow {
	win.on_submit_cb = cb
	return win
}

pub fn (mut win SimpleWindow) on_key_down(cb fn (mut win SimpleWindow, key gg.KeyCode)) &SimpleWindow {
	win.on_key_down_cb = cb
	return win
}

pub fn (mut win SimpleWindow) on_window_resize(cb fn (mut win SimpleWindow, w int, h int)) &SimpleWindow {
	win.on_resize_cb = cb
	return win
}

// Fluent & Concise Event Binding Aliases

pub fn (mut win SimpleWindow) bind_click(name string, cb VoidEventCallback) &SimpleWindow {
	return win.on_click(name, cb)
}

pub fn (mut win SimpleWindow) bind_change(name string, cb VoidEventCallback) &SimpleWindow {
	return win.on_change(name, cb)
}

pub fn (mut win SimpleWindow) bind_enter(name string, cb VoidEventCallback) &SimpleWindow {
	return win.on_enter(name, cb)
}

pub fn (mut win SimpleWindow) bind_hover(name string, cb VoidEventCallback) &SimpleWindow {
	return win.on_hover(name, cb)
}

pub fn (mut win SimpleWindow) bind_dblclick(name string, cb VoidEventCallback) &SimpleWindow {
	return win.on_dblclick(name, cb)
}

pub fn (mut win SimpleWindow) bind_double_click(name string, cb VoidEventCallback) &SimpleWindow {
	return win.on_dblclick(name, cb)
}

pub fn (mut win SimpleWindow) bind_right_click(name string, cb VoidEventCallback) &SimpleWindow {
	return win.on_right_click(name, cb)
}

pub fn (mut win SimpleWindow) bind_event(name string, event_type string, cb VoidEventCallback) &SimpleWindow {
	match event_type.to_lower().trim_space() {
		'click' { return win.on_click(name, cb) }
		'change' { return win.on_change(name, cb) }
		'enter' { return win.on_enter(name, cb) }
		'hover' { return win.on_hover(name, cb) }
		'dblclick', 'double_click', 'doubleclick' { return win.on_dblclick(name, cb) }
		'right_click', 'rightclick' { return win.on_right_click(name, cb) }
		else { return win.on_click(name, cb) }
	}
}

pub fn (mut win SimpleWindow) bind_key(key gg.KeyCode, cb fn (mut win SimpleWindow)) &SimpleWindow {
	prev_cb := win.on_key_down_cb
	win.on_key_down(fn [prev_cb, key, cb] (mut win SimpleWindow, k gg.KeyCode) {
		if prev_cb != unsafe { nil } {
			prev_cb(mut win, k)
		}
		if k == key {
			cb(mut win)
		}
	})
	return win
}

pub fn (mut win SimpleWindow) bind_shortcut(shortcut_str string, cb fn (mut win SimpleWindow)) &SimpleWindow {
	target_key := match shortcut_str.to_lower().trim_space() {
		'enter', 'return' { gg.KeyCode.enter }
		'escape', 'esc' { gg.KeyCode.escape }
		'space' { gg.KeyCode.space }
		'tab' { gg.KeyCode.tab }
		'backspace' { gg.KeyCode.backspace }
		'delete' { gg.KeyCode.delete }
		'up' { gg.KeyCode.up }
		'down' { gg.KeyCode.down }
		'left' { gg.KeyCode.left }
		'right' { gg.KeyCode.right }
		'f1' { gg.KeyCode.f1 }
		'f2' { gg.KeyCode.f2 }
		'f5' { gg.KeyCode.f5 }
		else { return win }
	}
	return win.bind_key(target_key, cb)
}

// Modal Dialog & Overlay API

pub fn (mut win SimpleWindow) show_modal(title string, message string, confirm_txt string, cancel_txt string, on_confirm VoidEventCallback) &SimpleWindow {
	win.modal_active = true
	win.modal_title = title
	win.modal_message = message
	win.modal_confirm_txt = if confirm_txt.len > 0 { confirm_txt } else { 'OK' }
	win.modal_cancel_txt = cancel_txt
	win.modal_on_confirm = on_confirm
	return win
}

pub fn (mut win SimpleWindow) hide_modal() &SimpleWindow {
	win.modal_active = false
	win.modal_on_confirm = unsafe { nil }
	win.modal_on_cancel = unsafe { nil }
	return win
}

// Validation Error API

pub fn (mut win SimpleWindow) set_validation_error(name string, err_msg string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.validation_err = err_msg
	}
	return win
}

pub fn (mut win SimpleWindow) clear_validation_error(name string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.validation_err = ''
	}
	return win
}

// Skeleton Placeholder Controls

pub fn (mut win SimpleWindow) add_skeleton(name string, w int, h int) &SimpleWindow {
	win.add_control(Control{
		name:        name
		kind:        'skeleton'
		w:           f32(w)
		h:           f32(h)
		is_skeleton: true
	})
	return win
}

// Tab Badge Counter API

pub fn (mut win SimpleWindow) set_tab_badge(container_name string, tab_index int, badge_text string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(container_name) {
		ctrl.tab_badges[tab_index] = badge_text
	}
	return win
}

// Search Filter & Highlighting API

pub fn (mut win SimpleWindow) set_table_search_filter(name string, query string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.search_query = query
	}
	return win
}

// RAD Builder Controls & Overlays

pub fn (mut win SimpleWindow) add_tag_input(name string, tags []string) &SimpleWindow {
	win.add_control(Control{
		name: name
		kind: 'tag_input'
		tags: tags
		h:    36
		w:    240
	})
	return win
}

pub fn (win &SimpleWindow) get_tags(name string) []string {
	if ctrl := win.control_map[name] {
		return ctrl.tags
	}
	return []string{}
}

pub fn (mut win SimpleWindow) set_tags(name string, tags []string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.tags = tags
	}
	return win
}

pub fn (mut win SimpleWindow) add_range_slider(name string, min f64, max f64, current_min f64, current_max f64) &SimpleWindow {
	win.add_control(Control{
		name:      name
		kind:      'range_slider'
		range_min: current_min
		range_max: current_max
		min_val:   min
		max_val:   max
		h:         30
		w:         200
	})
	return win
}

pub fn (win &SimpleWindow) get_range_values(name string) []f64 {
	if ctrl := win.control_map[name] {
		return [ctrl.range_min, ctrl.range_max]
	}
	return [0.0, 100.0]
}

pub fn (mut win SimpleWindow) set_range_values(name string, min_val f64, max_val f64) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.range_min = min_val
		ctrl.range_max = max_val
	}
	return win
}

pub fn (mut win SimpleWindow) add_code_editor(name string, initial_code string, lang string) &SimpleWindow {
	win.add_control(Control{
		name:       name
		kind:       'code_editor'
		text_value: initial_code
		code_lang:  lang
		h:          180
		w:          320
	})
	return win
}

pub fn (mut win SimpleWindow) add_drop_zone(name string, prompt string) &SimpleWindow {
	win.add_control(Control{
		name:        name
		kind:        'drop_zone'
		placeholder: prompt
		h:           100
		w:           260
	})
	return win
}

pub fn (win &SimpleWindow) get_dropped_files(name string) []string {
	if ctrl := win.control_map[name] {
		return ctrl.items
	}
	return []string{}
}

pub fn (win &SimpleWindow) get_files(name string) []string {
	return win.get_dropped_files(name)
}

pub fn (mut win SimpleWindow) clear_dropped_files(name string) &SimpleWindow {
	if mut ctrl := win.get_control_ptr(name) {
		ctrl.items.clear()
		ctrl.text_value = ''
	}
	return win
}

pub fn (mut win SimpleWindow) add_property_grid(name string, items []PropertyGridItem) &SimpleWindow {
	win.add_control(Control{
		name:           name
		kind:           'property_grid'
		property_items: items
		h:              f32(math.max(80, items.len * 32 + 20))
		w:              280
	})
	return win
}

pub fn (mut win SimpleWindow) add_sparkline(name string, values []f64) &SimpleWindow {
	win.add_control(Control{
		name:     name
		kind:     'sparkline'
		f64_list: values
		h:        40
		w:        180
	})
	return win
}

pub fn (mut win SimpleWindow) add_pagination(name string, current_page int, total_pages int) &SimpleWindow {
	win.add_control(Control{
		name:         name
		kind:         'pagination'
		current_page: current_page
		total_pages:  total_pages
		h:            36
		w:            240
	})
	return win
}

pub fn (mut win SimpleWindow) add_split_view(name string, split_ratio f32) &SimpleWindow {
	win.add_control(Control{
		name:        name
		kind:        'split_view'
		split_ratio: split_ratio
		h:           160
		w:           300
	})
	return win
}

pub fn (mut win SimpleWindow) push_toast(title string, message string, variant string, duration_ms int) &SimpleWindow {
	dur := if duration_ms > 0 { duration_ms } else { 3000 }
	win.toasts << Toast{
		id:          win.gen_id('toast')
		title:       title
		message:     message
		variant:     variant
		duration_ms: dur
		remaining:   f32(dur) / 1000.0
	}
	return win
}

pub fn (mut win SimpleWindow) show_command_palette(items []CommandItem) {
	win.command_palette_active = true
	win.command_palette_query = ''
	win.command_palette_items = items
	win.command_palette_sel = 0
}

pub fn (mut win SimpleWindow) hide_command_palette() {
	win.command_palette_active = false
}

pub fn (mut win SimpleWindow) show_context_menu(x f32, y f32, items []ContextMenuItem) {
	win.context_menu_active = true
	win.context_menu_x = x
	win.context_menu_y = y
	win.context_menu_items = items
}

pub fn (mut win SimpleWindow) hide_context_menu() {
	win.context_menu_active = false
}

// =============================================================================
// Interval Timers & Scheduled Callbacks
// =============================================================================

// set_interval creates or updates a recurring timer with ID `id` running every `interval_ms` milliseconds.
pub fn (mut win SimpleWindow) set_interval(id string, interval_ms int, cb fn (mut win SimpleWindow)) &SimpleWindow {
	win.timers[id] = &IntervalTimer{
		id:          id
		interval_ms: interval_ms
		running:     true
		one_shot:    false
		last_tick:   time.ticks()
		callback:    cb
	}
	return win
}

// set_timeout creates or updates a one-shot delay timer firing once after `delay_ms` milliseconds.
pub fn (mut win SimpleWindow) set_timeout(id string, delay_ms int, cb fn (mut win SimpleWindow)) &SimpleWindow {
	win.timers[id] = &IntervalTimer{
		id:          id
		interval_ms: delay_ms
		running:     true
		one_shot:    true
		last_tick:   time.ticks()
		callback:    cb
	}
	return win
}

// add_timer is an alias for `set_interval`.
pub fn (mut win SimpleWindow) add_timer(id string, interval_ms int, cb fn (mut win SimpleWindow)) &SimpleWindow {
	return win.set_interval(id, interval_ms, cb)
}

// stop_timer stops and removes a scheduled timer by ID.
pub fn (mut win SimpleWindow) stop_timer(id string) &SimpleWindow {
	if id in win.timers {
		win.timers.delete(id)
	}
	return win
}

// clear_interval is an alias for `stop_timer`.
pub fn (mut win SimpleWindow) clear_interval(id string) &SimpleWindow {
	return win.stop_timer(id)
}

// clear_timeout is an alias for `stop_timer`.
pub fn (mut win SimpleWindow) clear_timeout(id string) &SimpleWindow {
	return win.stop_timer(id)
}

// pause_timer pauses a running timer without removing its registration.
pub fn (mut win SimpleWindow) pause_timer(id string) &SimpleWindow {
	if mut tmr := win.timers[id] {
		tmr.running = false
	}
	return win
}

// start_timer resumes or starts a paused timer.
pub fn (mut win SimpleWindow) start_timer(id string) &SimpleWindow {
	if mut tmr := win.timers[id] {
		tmr.running = true
		tmr.last_tick = time.ticks()
	}
	return win
}

// reset_timer resets the timer's elapsed time tracker.
pub fn (mut win SimpleWindow) reset_timer(id string) &SimpleWindow {
	if mut tmr := win.timers[id] {
		tmr.last_tick = time.ticks()
	}
	return win
}

// is_timer_running returns true if a timer exists and is currently active.
pub fn (win &SimpleWindow) is_timer_running(id string) bool {
	if tmr := win.timers[id] {
		return tmr.running
	}
	return false
}

// set_timer_interval dynamically adjusts the duration interval of an existing timer.
pub fn (mut win SimpleWindow) set_timer_interval(id string, interval_ms int) &SimpleWindow {
	if mut tmr := win.timers[id] {
		tmr.interval_ms = interval_ms
	}
	return win
}

// clear_all_timers stops and removes all scheduled timers in the window.
pub fn (mut win SimpleWindow) clear_all_timers() &SimpleWindow {
	win.timers.clear()
	return win
}

// process_timers checks active timers and triggers scheduled callbacks when intervals expire.
pub fn (mut win SimpleWindow) process_timers() {
	if win.timers.len == 0 {
		return
	}
	now := time.ticks()
	mut finished_ids := []string{}

	mut timer_ids := []string{}
	for id, tmr in win.timers {
		if tmr.running {
			timer_ids << id
		}
	}

	for id in timer_ids {
		if mut tmr := win.timers[id] {
			if !tmr.running {
				continue
			}
			if tmr.last_tick == 0 {
				tmr.last_tick = now
				continue
			}
			if now - tmr.last_tick >= tmr.interval_ms {
				tmr.last_tick = now
				if tmr.callback != unsafe { nil } {
					tmr.callback(mut win)
				}
				if tmr.one_shot {
					tmr.running = false
					finished_ids << id
				}
			}
		}
	}

	for id in finished_ids {
		win.timers.delete(id)
	}
}

// Execution Loop

fn frame_cb(mut win SimpleWindow) {
	win.gg_ctx.begin()
	win.render_ui()
	win.gg_ctx.end()
}

fn event_cb(e &gg.Event, mut win SimpleWindow) {
	win.handle_event(e)
}

pub fn (mut win SimpleWindow) run() {
	resolved_font := if win.font_path.len > 0 && os.exists(win.font_path) {
		win.font_path
	} else {
		resolve_window_font_path()
	}

	win.gg_ctx = gg.new_context(
		width:            win.width
		height:           win.height
		window_title:     win.title
		user_data:        win
		frame_fn:         frame_cb
		event_fn:         event_cb
		bg_color:         parse_hex_color(win.theme.background_color)
		fullscreen:       win.fullscreen
		enable_dragndrop: true
		font_path:        resolved_font
	)
	win.gg_ctx.run()
}
