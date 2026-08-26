// Module simplegui - Core UI Framework for V
// File: control.v
//
// Description:
//   This file defines the primary data structures (structs) and types used by SimpleGUI
//   to represent UI elements (Controls). A Control represents any visual element on screen,
//   such as a Button, Slider, TextBox, CheckBox, DropDown, ListBox, Data Table, or Custom Widget.
//   It also contains chainable setter methods for configuring element sizing, spacing, positioning,
//   typography, colors, and event listeners.

module simplegui

// VoidEventCallback represents an event handler callback function.
// It receives a mutable reference to the `SimpleWindow`, allowing handlers to modify window state or other controls.
pub type VoidEventCallback = fn (mut win SimpleWindow)

// StringEventCallback represents a change event handler callback function receiving the changed value.
pub type StringEventCallback = fn (mut win SimpleWindow, val string)

// ControlValidator represents a custom input validation callback function for text inputs.
// It receives the current string value and returns an error message string (or empty string if valid).
pub type ControlValidator = fn (val string) string

// TreeNode represents a single hierarchical node in a TreeView control.
// Tree nodes can have nested child nodes to display folder trees, file systems, or nested lists.
pub struct TreeNode {
pub mut:
	id       string     // Unique identifier for the tree node
	text     string     // Display label text shown next to the node
	icon     string     // Optional icon name or unicode character to display
	children []TreeNode // List of nested child nodes contained within this node
	expanded bool       // Whether child nodes are currently expanded (visible) or collapsed
}

// GroupConfig defines visual configuration parameters for container cards or group boxes.
// Group boxes draw a rounded border, background color, and header caption around contained controls.
pub struct GroupConfig {
pub mut:
	title             string // Header text displayed at the top of the group box
	border            bool = true // Whether to draw an outer border around the group container
	border_width      f32  = 1.0  // Border line thickness in pixels
	border_color      string      // Custom hex color string for the border line (e.g. '#3b82f6')
	corner_radius     f32 = 12.0  // Corner roundness radius in pixels
	bg_color          string      // Background fill color string
	padding           int = 12    // Inner spacing padding in pixels around child elements
	shadow            bool        // Whether to render a subtle drop-shadow effect
	show_caption      bool = true // Whether to render the title caption header
	caption_color     string      // Color of the title text header
	caption_alignment string = 'left' // Header alignment: 'left', 'center', or 'right'
}

// ToolbarItem represents an interactive action button displayed within a horizontal Toolbar control.
pub struct ToolbarItem {
pub mut:
	icon     string            // Icon representation or symbol (e.g. '[Folder]', '[Save]', '[Settings]')
	tooltip  string            // Tooltip hint text displayed when hovering over the toolbar item
	on_click VoidEventCallback = unsafe { nil } // Callback function executed when clicked
}

// PropertyGridItem represents a single key-value entry row inside an interactive Property Grid widget.
pub struct PropertyGridItem {
pub mut:
	name    string   // Name of the property (e.g. 'Font Size', 'Enabled', 'Theme')
	val     string   // Current string value of the property
	kind    string   // Data input type editor: "text", "bool", "number", "color", "choice"
	choices []string // Available dropdown selection choices (used when kind is "choice")
}

// Toast represents a temporary notification banner popup displayed at the corner of the window.
pub struct Toast {
pub mut:
	id          string // Unique identifier for tracking and dismissing the toast
	title       string // Bold headline text of the toast message
	message     string // Body text content of the notification
	variant     string // Alert type/color theme: "info" (blue), "success" (green), "warning" (yellow), "error" (red)
	icon_path   string // Custom or auto-resolved icon asset path
	created_at  i64    // Unix timestamp (milliseconds) when the toast was created
	duration_ms int = 3000 // Display duration in milliseconds before auto-dismissing
	remaining   f32 = 3.0  // Remaining time countdown in seconds
}

// CommandItem represents a selectable command entry in the Spotlight / Command Palette launcher (Ctrl+K / Cmd+K).
pub struct CommandItem {
pub mut:
	id         string            // Unique identifier for the command action
	title      string            // Human-readable command title shown in the palette search list
	category   string            // Category grouping header (e.g. 'Navigation', 'Settings', 'Actions')
	shortcut   string            // Keyboard shortcut hint string (e.g. 'Ctrl+Shift+P')
	icon_path  string            // Custom icon asset path
	on_execute VoidEventCallback = unsafe { nil } // Callback executed when selected
}

// ContextMenuItem represents an individual action item in a popup Right-Click Context Menu.
pub struct ContextMenuItem {
pub mut:
	id        string            // Unique item identifier
	title     string            // Display label text
	icon      string            // Icon or emoji displayed next to the text label
	icon_path string            // Custom image icon asset path
	shortcut  string            // Keyboard shortcut indicator
	on_select VoidEventCallback = unsafe { nil } // Callback function triggered upon clicking the menu item
}

// MenuItem represents an individual action or entry in a window Menu Bar dropdown menu.
pub struct MenuItem {
pub mut:
	id           string            // Unique identifier
	title        string            // Display text label (e.g. 'Open...', 'Save As')
	shortcut     string            // Keyboard shortcut hint (e.g. 'Ctrl+O', 'Cmd+S')
	icon         string            // Optional icon/emoji
	is_separator bool              // Whether this item is a divider line
	disabled     bool              // Whether this item is disabled/grayed out
	on_select    VoidEventCallback = unsafe { nil } // Callback invoked upon clicking this item
}

// MenuCategory represents a top-level category in a window Menu Bar (e.g. 'File', 'Edit', 'View', 'Help').
pub struct MenuCategory {
pub mut:
	title string     // Title displayed on the top Menu Bar
	items []MenuItem // Sub-menu items displayed in the dropdown
}

// SidebarItem represents an individual navigation destination in a Collapsible Sidebar or Nav Rail.
pub struct SidebarItem {
pub mut:
	id        string            // Unique item identifier
	title     string            // Navigation label text
	icon      string            // Vector icon glyph name or emoji
	badge     string            // Optional pill badge text (e.g. '5', 'NEW')
	is_active bool              // Whether item is the currently selected active view
	on_click  VoidEventCallback = unsafe { nil } // Click callback
}

// TreeTableRow represents a row in a hierarchical Tree Table data grid with nested children.
pub struct TreeTableRow {
pub mut:
	id          string         // Unique row identifier
	values      []string       // Column cell values
	children    []TreeTableRow // Nested sub-rows
	is_expanded bool           // Expansion state
}

// CalendarEvent represents an event marker in a Month Calendar view.
pub struct CalendarEvent {
pub mut:
	date  string // Date string format YYYY-MM-DD
	title string // Event title
	color string // Dot highlight color hex
}

// DrawerItem represents an interactive menu option or section header in a slide-over Drawer panel.
pub struct DrawerItem {
pub mut:
	id        string            // Unique identifier
	title     string            // Primary item label
	subtitle  string            // Optional secondary description text
	icon      string            // Vector icon glyph name (e.g. 'search', 'gear', 'database', 'bell')
	badge     string            // Optional badge text (e.g. '12', 'PRO')
	is_active bool              // Active state highlight
	is_header bool              // Section header divider
	on_click  VoidEventCallback = unsafe { nil } // Click callback handler
}

// Control is the unified structure for every GUI element in SimpleGUI.
// Whether it's a simple button, slider, text input, checkbox, or complex widget,
// its state, dimensions, styling properties, and event handlers are stored in this struct.
@[heap]
pub struct Control {
pub mut:
	name           string   // Unique ID/name of the control (used to reference it in window lookup maps)
	kind           string   // Control type identifier (e.g. 'button', 'label', 'textbox', 'slider', 'table')
	title          string   // Main text label or display title
	text_value     string   // Text input value or current text content
	bool_value     bool     // Boolean state value (e.g. checked state for CheckBox/RadioButton/Switch)
	int_value      int      // Integer numerical value (e.g. active tab index, rating value, list index)
	f64_value      f64      // Floating point value (e.g. slider position, progress percentage 0..100)
	items          []string // Options list for DropDown, ListBox, MultiSelect, RadioGroup, Tabs
	items_selected []string // Selected items list for multi-select ListBoxes or Tag Inputs
	f64_list       []f64    // List of numeric values (used for Sparkline graphs, Line Charts, Bar Charts)
	headers        []string // Column headers list (used for Data Tables)
	rows           [][]string // 2D matrix of string cells (used for Data Table rows)
	tree_nodes     []TreeNode // Hierarchical tree nodes (used for TreeView controls)
	props          map[string]string // Generic key-value property bag for extended custom settings
	placeholder    string   // Placeholder hint text displayed in empty text inputs
	min_val        f64      // Minimum allowed numeric value (for Sliders, Number Inputs, Range Sliders)
	max_val        f64 = 100.0 // Maximum allowed numeric value (default 100.0)
	step           f64 = 1.0   // Step increment value for sliders or spinners
	// Geometry (Calculated screen position and bounding box size in pixels)
	x f32 // X coordinate position (distance from left edge of parent window/container)
	y f32 // Y coordinate position (distance from top edge of parent window/container)
	w f32 = 200.0 // Width of control bounding box in pixels
	h f32 = 30.0  // Height of control bounding box in pixels
	// Layout properties
	alignment      string // Alignment mode within container ('left', 'center', 'right', 'stretch')
	expand_fill    bool   // If true, control automatically expands to fill available width/height
	container_name string // Name of parent container box/card/tab if nested inside one
	// Visual styling overrides
	bg_color      string // Custom background color override in hex format ('#ffffff' or '#1e293b')
	font_color    string // Custom text label color override in hex format
	accent_color  string // Primary accent tint color for active/highlight states
	tooltip       string // Tooltip explanation text displayed on hover
	custom_cursor string // Custom cursor type name (e.g. 'pointer', 'ibeam', 'hand', 'crosshair')
	group_cfg     GroupConfig // Container box configuration (if control is a Group Box container)
	// Interactive control states
	visible         bool = true // Whether the control is visible and rendered on screen
	disabled        bool        // If true, control is grayed out and ignores user interactions
	is_focused      bool        // Whether this control currently has keyboard input focus
	is_hovered      bool        // Whether mouse pointer is currently positioned over this control
	is_pressed      bool        // Whether mouse button is currently held down over this control
	scroll_offset_y f32         // Vertical scroll offset (for scrollable containers, lists, or text areas)
	caret_pos       int         // Text cursor position index (for text input editing)
	sel_start       int = -1    // Selection start index (-1 if no text selection)
	sel_end         int = -1    // Selection end index (-1 if no text selection)
	undo_stack      []string    // Text history stack for Cmd+Z / Ctrl+Z undo operations
	redo_stack      []string    // Text history stack for Cmd+Shift+Z / Ctrl+Y redo operations
	validation_err  string      // Validation error message (if text validation failed)
	selected_row    int = -1    // Selected row index (for Data Tables or List views)
	variant         string      // Visual style variant (e.g. 'primary', 'secondary', 'danger', 'ghost')
	is_expanded     bool        // Expansion state (for Accordions, Collapsibles, and Tree Nodes)
	// Data Table sorting state
	sort_col int  = -1 // Currently sorted column index (-1 means unsorted)
	sort_asc bool = true // Sort direction: true = ascending (A-Z, 0-9), false = descending
	// Detailed Geometry & Spacing (Inner padding and outer margin in pixels)
	padding_top    f32 // Inner padding spacing at top edge
	padding_bottom f32 // Inner padding spacing at bottom edge
	padding_left   f32 // Inner padding spacing at left edge
	padding_right  f32 // Inner padding spacing at right edge
	margin_top     f32 // Outer margin spacing above control
	margin_bottom  f32 // Outer margin spacing below control
	margin_left    f32 // Outer margin spacing to left of control
	margin_right   f32 // Outer margin spacing to right of control
	// Typography styling
	font_size  int    // Font size in points/pixels
	font_bold  bool   // Bold font weight flag
	font_name  string // Font family name
	text_align string // Horizontal text alignment ('left', 'center', 'right')
	// Border & Opacity
	border_width  f32        // Thickness of outer stroke border line in pixels
	border_color  string     // Color hex string for outer stroke border
	corner_radius f32 = 6.0  // Corner rounding radius in pixels
	opacity       f64 = 1.0  // Visual opacity opacity level (1.0 = fully opaque, 0.0 = transparent)
	// Advanced RAD (Rapid Application Development) Controls State
	range_min       f64      // Lower bound value for Range Slider
	range_max       f64 = 100.0 // Upper bound value for Range Slider
	is_dragging_min bool     // Dragging indicator state for Range Slider min thumb handle
	is_dragging_max bool     // Dragging indicator state for Range Slider max thumb handle
	tags            []string // List of active string tags (for Tag Input control)
	code_lang       string   // Syntax highlighting language name (for Code Editor control)
	split_ratio     f32 = 0.5 // Split pane divider ratio (0.0 to 1.0) for Splitter containers
	property_items  []PropertyGridItem // Active item list for Property Grid controls
	total_pages     int = 1  // Total number of pages (for Pagination control)
	current_page    int = 1  // Active current page number (for Pagination control)
	last_click_time i64      // Timestamp of last click (used for double-click detection)
	tab_badges      map[int]string // Optional notification badges on tab titles (map of tab_index -> badge text)
	tab_icons       map[int]string // Optional icon image paths on tab titles (map of tab_index -> icon path)
	icon_path       string   // Custom icon asset path (for buttons, input fields, status bars, etc.)
	search_query    string   // Active search filtering text query (for Search inputs/tables)
	is_skeleton     bool     // Loading placeholder state (renders animated skeleton gray boxes)
	// Modern UI & UX Enhancements State
	icon_vector       string             // Vector icon glyph name (e.g. 'search', 'gear', 'check', 'close')
	is_collapsed      bool               // Collapse state for Sidebars or panels
	sidebar_items     []SidebarItem      // Items list for Sidebar or NavRail
	cal_year          int = 2026         // Year for Month Calendar
	cal_month         int = 8            // Month (1-12) for Month Calendar
	cal_selected_day  int = 1            // Selected day of month (1-31)
	cal_events        []CalendarEvent    // Marked events for Month Calendar
	heatmap_data      [][]int            // 2D intensity matrix (7 days x N weeks) for Activity Heatmap
	heatmap_levels    []string           // Color hex scale levels for Heatmap
	tree_table_nodes  []TreeTableRow     // Nested rows for Tree Table
	mask_pattern      string             // Mask formatting template (e.g. '(###) ###-####')
	is_editing        bool               // Active edit mode flag for Inline Editable Label
	show_clear        bool = true        // Show (x) clear button on search/input fields
	show_pwd_toggle   bool = true        // Show [Show/Hide] toggle eye button on password fields
	pwd_revealed      bool               // Plain text reveal state for password fields
	markdown_content  string             // Raw markdown document string for Markdown Viewer
	elevation         int                // Soft drop shadow elevation level (0..4)
	// Event Callback Handlers
	on_click       VoidEventCallback   = unsafe { nil } // Triggered on single left click
	on_change      VoidEventCallback   = unsafe { nil } // Triggered when value/text changes
	on_change_str  StringEventCallback = unsafe { nil } // Triggered when value/text changes (with string payload)
	on_enter       VoidEventCallback   = unsafe { nil } // Triggered when Enter key pressed in input field
	on_row_click   VoidEventCallback = unsafe { nil } // Triggered when row clicked in Data Table
	on_hover       VoidEventCallback = unsafe { nil } // Triggered when mouse enters hover boundary
	on_dblclick    VoidEventCallback = unsafe { nil } // Triggered on double click
	on_right_click VoidEventCallback = unsafe { nil } // Triggered on right mouse click
}

// -----------------------------------------------------------------------------
// Method Chain Setters
// -----------------------------------------------------------------------------
// Method chaining allows developers to fluently configure controls upon creation:
// Example: win.add_button('btn', 'Click Me').set_width(120).set_bg_color('#2563eb')

// set_width sets the explicit width of the control in pixels and returns the control reference.
pub fn (c &Control) set_width(w int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.w = f32(w)
	}
	return c
}

// set_height sets the explicit height of the control in pixels and returns the control reference.
pub fn (c &Control) set_height(h int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.h = f32(h)
	}
	return c
}

// set_size sets both width and height of the control simultaneously in pixels.
pub fn (c &Control) set_size(w int, h int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.w = f32(w)
		ptr.h = f32(h)
	}
	return c
}

// set_position sets explicit absolute screen coordinates (x, y) for the control.
pub fn (c &Control) set_position(x int, y int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.x = f32(x)
		ptr.y = f32(y)
	}
	return c
}

// set_padding applies uniform inner padding (in pixels) on all four sides of the control.
pub fn (c &Control) set_padding(p int) &Control {
	unsafe {
		mut ptr := &Control(c)
		pf := f32(p)
		ptr.padding_top = pf
		ptr.padding_bottom = pf
		ptr.padding_left = pf
		ptr.padding_right = pf
	}
	return c
}

// set_padding_trbl sets individual inner padding values for Top, Right, Bottom, and Left sides.
pub fn (c &Control) set_padding_trbl(top int, right int, bottom int, left int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.padding_top = f32(top)
		ptr.padding_right = f32(right)
		ptr.padding_bottom = f32(bottom)
		ptr.padding_left = f32(left)
	}
	return c
}

// set_padding_xy sets horizontal (px) and vertical (py) inner padding values.
pub fn (c &Control) set_padding_xy(px int, py int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.padding_left = f32(px)
		ptr.padding_right = f32(px)
		ptr.padding_top = f32(py)
		ptr.padding_bottom = f32(py)
	}
	return c
}

// set_margin applies uniform outer margin spacing (in pixels) around all four sides of the control.
pub fn (c &Control) set_margin(m int) &Control {
	unsafe {
		mut ptr := &Control(c)
		mf := f32(m)
		ptr.margin_top = mf
		ptr.margin_bottom = mf
		ptr.margin_left = mf
		ptr.margin_right = mf
	}
	return c
}

// set_margin_trbl sets individual outer margin spacing for Top, Right, Bottom, and Left sides.
pub fn (c &Control) set_margin_trbl(top int, right int, bottom int, left int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.margin_top = f32(top)
		ptr.margin_right = f32(right)
		ptr.margin_bottom = f32(bottom)
		ptr.margin_left = f32(left)
	}
	return c
}

// set_margin_xy sets horizontal (mx) and vertical (my) outer margin spacing.
pub fn (c &Control) set_margin_xy(mx int, my int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.margin_left = f32(mx)
		ptr.margin_right = f32(mx)
		ptr.margin_top = f32(my)
		ptr.margin_bottom = f32(my)
	}
	return c
}

// set_margin_top sets outer margin spacing above the control.
pub fn (c &Control) set_margin_top(top int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.margin_top = f32(top)
	}
	return c
}

// set_margin_bottom sets outer margin spacing below the control.
pub fn (c &Control) set_margin_bottom(bottom int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.margin_bottom = f32(bottom)
	}
	return c
}

// set_margin_left sets outer margin spacing to the left of the control.
pub fn (c &Control) set_margin_left(left int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.margin_left = f32(left)
	}
	return c
}

// set_margin_right sets outer margin spacing to the right of the control.
pub fn (c &Control) set_margin_right(right int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.margin_right = f32(right)
	}
	return c
}

// set_alignment sets alignment within container ('left', 'center', 'right', 'stretch').
pub fn (c &Control) set_alignment(align string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.alignment = align
	}
	return c
}

// expand_fill enables auto-expanding width/height to fill available container space.
pub fn (c &Control) expand_fill() &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.expand_fill = true
	}
	return c
}

// set_expand_fill sets whether the control should auto-expand to fill available space.
pub fn (c &Control) set_expand_fill(expand bool) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.expand_fill = expand
	}
	return c
}

// set_tooltip sets helpful popover tooltip text displayed when mouse hovers over the control.
pub fn (c &Control) set_tooltip(tip string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.tooltip = tip
	}
	return c
}

// set_cursor sets custom mouse pointer appearance when hovering over this control (e.g. 'pointer', 'ibeam').
pub fn (c &Control) set_cursor(cursor string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.custom_cursor = cursor
	}
	return c
}

// set_font_size configures text font size in points/pixels for this control.
pub fn (c &Control) set_font_size(size int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.font_size = size
	}
	return c
}

// set_font_bold enables or disables bold font formatting.
pub fn (c &Control) set_font_bold(bold bool) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.font_bold = bold
	}
	return c
}

// set_font_name sets specific font family name for rendering text.
pub fn (c &Control) set_font_name(font_name string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.font_name = font_name
	}
	return c
}

// set_placeholder sets placeholder hint text for input controls.
pub fn (c &Control) set_placeholder(ph string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.placeholder = ph
	}
	return c
}

// set_text_align sets text alignment within control bounds ('left', 'center', 'right').
pub fn (c &Control) set_text_align(align string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.text_align = align
	}
	return c
}

// set_bg_color sets custom background color hex string (e.g. '#1e293b').
pub fn (c &Control) set_bg_color(color string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.bg_color = color
	}
	return c
}

// set_font_color sets custom text color hex string (e.g. '#f8fafc').
pub fn (c &Control) set_font_color(color string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.font_color = color
	}
	return c
}

// set_accent_color sets custom accent highlight color hex string.
pub fn (c &Control) set_accent_color(color string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.accent_color = color
	}
	return c
}

// set_border configures outer border stroke width (in pixels) and border color hex string.
pub fn (c &Control) set_border(width f32, color string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.border_width = width
		ptr.border_color = color
	}
	return c
}

// set_corner_radius configures corner rounding radius in pixels.
pub fn (c &Control) set_corner_radius(radius f32) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.corner_radius = radius
	}
	return c
}

// set_opacity sets visual opacity ratio from 0.0 (fully invisible) to 1.0 (fully opaque).
pub fn (c &Control) set_opacity(opacity f64) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.opacity = opacity
	}
	return c
}

// set_visible shows (true) or hides (false) the control.
pub fn (c &Control) set_visible(visible bool) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.visible = visible
	}
	return c
}

// set_enabled enables (true) or disables/grays out (false) user interactions with the control.
pub fn (c &Control) set_enabled(enabled bool) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.disabled = !enabled
	}
	return c
}

// has_selection returns true if there is an active text selection range.
pub fn (ctrl &Control) has_selection() bool {
	return ctrl.sel_start >= 0 && ctrl.sel_end >= 0 && ctrl.sel_start != ctrl.sel_end
}

// selection_range returns normalized (start, end) text selection indices clamped to text length.
pub fn (ctrl &Control) selection_range() (int, int) {
	if !ctrl.has_selection() {
		return 0, 0
	}
	len := ctrl.text_value.len
	mut s := ctrl.sel_start
	mut e := ctrl.sel_end
	if s > e {
		s, e = e, s
	}
	if s < 0 {
		s = 0
	}
	if e > len {
		e = len
	}
	if s > len {
		s = len
	}
	return s, e
}

// selected_text returns the currently selected text substring.
pub fn (ctrl &Control) selected_text() string {
	if !ctrl.has_selection() {
		return ''
	}
	s, e := ctrl.selection_range()
	if s >= e || s >= ctrl.text_value.len {
		return ''
	}
	return ctrl.text_value[s..e]
}

// clear_selection clears active text selection.
pub fn (mut ctrl Control) clear_selection() {
	ctrl.sel_start = -1
	ctrl.sel_end = -1
}

// select_all selects all text in the control.
pub fn (mut ctrl Control) select_all() {
	ctrl.sel_start = 0
	ctrl.sel_end = ctrl.text_value.len
	ctrl.caret_pos = ctrl.text_value.len
}

// delete_selected_text removes the selected text range from text_value and updates caret_pos.
pub fn (mut ctrl Control) delete_selected_text() {
	if !ctrl.has_selection() {
		return
	}
	ctrl.save_undo_state()
	s, e := ctrl.selection_range()
	ctrl.text_value = ctrl.text_value[0..s] + ctrl.text_value[e..]
	ctrl.caret_pos = s
	ctrl.clear_selection()
}

// save_undo_state pushes the current text_value onto the undo stack before mutation.
pub fn (mut ctrl Control) save_undo_state() {
	if ctrl.undo_stack.len == 0 || ctrl.undo_stack[ctrl.undo_stack.len - 1] != ctrl.text_value {
		ctrl.undo_stack << ctrl.text_value
		if ctrl.undo_stack.len > 50 {
			ctrl.undo_stack = ctrl.undo_stack[ctrl.undo_stack.len - 50..]
		}
		ctrl.redo_stack.clear()
	}
}

// undo restores the previous text value from the undo stack.
pub fn (mut ctrl Control) undo() bool {
	if ctrl.undo_stack.len > 0 {
		ctrl.redo_stack << ctrl.text_value
		prev := ctrl.undo_stack.pop()
		ctrl.text_value = prev
		ctrl.caret_pos = ctrl.text_value.len
		ctrl.clear_selection()
		return true
	}
	return false
}

// redo restores the next text value from the redo stack.
pub fn (mut ctrl Control) redo() bool {
	if ctrl.redo_stack.len > 0 {
		ctrl.undo_stack << ctrl.text_value
		next := ctrl.redo_stack.pop()
		ctrl.text_value = next
		ctrl.caret_pos = ctrl.text_value.len
		ctrl.clear_selection()
		return true
	}
	return false
}

// set_stat updates stat card title, value, delta text and trend polarity.
pub fn (c &Control) set_stat(title string, val string, delta string, is_pos bool) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.title = title
		ptr.text_value = val
		ptr.placeholder = delta
		ptr.bool_value = is_pos
	}
	return c
}

// set_sparkline sets numeric data points for the trend graph.
pub fn (c &Control) set_sparkline(data []f64) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.f64_list = data.clone()
	}
	return c
}

// set_code_lang sets the syntax highlighting language for Code Studio.
pub fn (c &Control) set_code_lang(lang string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.code_lang = lang
	}
	return c
}

// set_current_step sets the active step index for Wizard Stepper.
pub fn (c &Control) set_current_step(step int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.int_value = step
	}
	return c
}

// set_progress_pct sets the numeric percentage value (0.0 to 100.0) for Radial Gauges / Donut Charts.
pub fn (c &Control) set_progress_pct(pct f64) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.f64_value = pct
	}
	return c
}

// set_image_path updates the primary image or avatar file path of the control.
pub fn (c &Control) set_image_path(path string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.text_value = path
	}
	return c
}

// set_image_paths updates the list of image file paths for image gallery or carousel controls.
pub fn (c &Control) set_image_paths(paths []string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.items = paths.clone()
	}
	return c
}

// set_captions updates the list of captions for image gallery controls.
pub fn (c &Control) set_captions(captions []string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.items_selected = captions.clone()
	}
	return c
}

// set_user_profile updates avatar, display name, handle, role, bio, and online status for User Profile cards.
pub fn (c &Control) set_user_profile(avatar string, name string, handle string, role string, bio string, is_online bool) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.text_value = avatar
		ptr.title = name
		ptr.placeholder = handle
		ptr.bool_value = is_online
		if ptr.items.len >= 3 {
			ptr.items[0] = role
			ptr.items[1] = bio
		} else {
			ptr.items = [role, bio, '[Message]']
		}
	}
	return c
}

// set_product_info updates product image, title, description, price, and badge tag.
pub fn (c &Control) set_product_info(image string, title string, desc string, price string, badge string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.text_value = image
		ptr.title = title
		ptr.placeholder = desc
		if ptr.items.len >= 4 {
			ptr.items[0] = price
			ptr.items[1] = badge
		} else {
			ptr.items = [price, badge, '[Buy Now]', '4.9 *']
		}
	}
	return c
}

// set_media_track updates media player track information and playback state.
pub fn (c &Control) set_media_track(cover string, title string, artist string, duration_sec int, elapsed_sec int, is_playing bool) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.text_value = cover
		ptr.title = title
		ptr.placeholder = artist
		ptr.int_value = duration_sec
		ptr.min_val = f64(elapsed_sec)
		ptr.bool_value = is_playing
	}
	return c
}

// set_is_playing updates the active playback state (true = playing, false = paused) for media players.
pub fn (c &Control) set_is_playing(playing bool) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.bool_value = playing
	}
	return c
}

// set_elevation sets the soft drop shadow elevation level (0 to 4).
pub fn (c &Control) set_elevation(elevation int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.elevation = elevation
	}
	return c
}

// set_vector_icon sets a procedural vector icon glyph name (e.g. 'search', 'gear', 'check').
pub fn (c &Control) set_vector_icon(icon string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.icon_vector = icon
	}
	return c
}

// set_collapsed sets the collapsed state of the control (e.g. Sidebar or Accordion).
pub fn (c &Control) set_collapsed(collapsed bool) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.is_collapsed = collapsed
	}
	return c
}

// set_mask_pattern sets the mask formatting template string for masked inputs.
pub fn (c &Control) set_mask_pattern(pattern string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.mask_pattern = pattern
	}
	return c
}

// set_markdown_content sets the markdown document content string.
pub fn (c &Control) set_markdown_content(md string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.markdown_content = md
	}
	return c
}

