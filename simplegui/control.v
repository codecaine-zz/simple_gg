module simplegui

pub type VoidEventCallback = fn (mut win SimpleWindow)

pub type ControlValidator = fn (val string) string

pub struct TreeNode {
pub mut:
	id       string
	text     string
	icon     string
	children []TreeNode
	expanded bool
}

pub struct GroupConfig {
pub mut:
	title             string
	border            bool   = true
	border_width      f32    = 1.0
	border_color      string
	corner_radius     f32    = 12.0
	bg_color          string
	padding           int    = 12
	shadow            bool
	show_caption      bool   = true
	caption_color     string
	caption_alignment string = 'left'
}

@[heap]
pub struct Control {
pub mut:
	name            string
	kind            string
	title           string
	text_value      string
	bool_value      bool
	int_value       int
	f64_value       f64
	items           []string
	items_selected  []string
	f64_list        []f64
	headers         []string
	rows            [][]string
	tree_nodes      []TreeNode
	props           map[string]string
	placeholder     string
	min_val         f64
	max_val         f64 = 100.0
	step            f64 = 1.0
	// Geometry
	x               f32
	y               f32
	w               f32 = 200.0
	h               f32 = 30.0
	// Layout properties
	alignment       string
	expand_fill     bool
	container_name  string
	// Visual styling
	bg_color        string
	font_color      string
	accent_color    string
	tooltip         string
	custom_cursor   string
	group_cfg       GroupConfig
	// Control states
	visible         bool = true
	disabled        bool
	is_focused      bool
	is_hovered      bool
	is_pressed      bool
	scroll_offset_y f32
	caret_pos       int
	validation_err  string
	selected_row    int = -1
	variant         string
	is_expanded     bool
	// Detailed Geometry & Spacing
	padding_top     f32
	padding_bottom  f32
	padding_left    f32
	padding_right   f32
	margin_top      f32
	margin_bottom   f32
	margin_left     f32
	margin_right    f32
	// Typography
	font_size       int
	font_bold       bool
	font_name       string
	text_align      string
	// Border & Opacity
	border_width    f32
	border_color    string
	corner_radius   f32 = 6.0
	opacity         f64 = 1.0
	// Callbacks
	on_click        VoidEventCallback = unsafe { nil }
	on_change       VoidEventCallback = unsafe { nil }
	on_enter        VoidEventCallback = unsafe { nil }
	on_row_click    VoidEventCallback = unsafe { nil }
}

pub fn (c &Control) set_width(w int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.w = f32(w)
	}
	return c
}

pub fn (c &Control) set_height(h int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.h = f32(h)
	}
	return c
}

pub fn (c &Control) set_size(w int, h int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.w = f32(w)
		ptr.h = f32(h)
	}
	return c
}

pub fn (c &Control) set_position(x int, y int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.x = f32(x)
		ptr.y = f32(y)
	}
	return c
}

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

pub fn (c &Control) set_margin_top(top int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.margin_top = f32(top)
	}
	return c
}

pub fn (c &Control) set_margin_bottom(bottom int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.margin_bottom = f32(bottom)
	}
	return c
}

pub fn (c &Control) set_margin_left(left int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.margin_left = f32(left)
	}
	return c
}

pub fn (c &Control) set_margin_right(right int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.margin_right = f32(right)
	}
	return c
}

pub fn (c &Control) set_alignment(align string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.alignment = align
	}
	return c
}

pub fn (c &Control) expand_fill() &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.expand_fill = true
	}
	return c
}

pub fn (c &Control) set_expand_fill(expand bool) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.expand_fill = expand
	}
	return c
}

pub fn (c &Control) set_tooltip(tip string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.tooltip = tip
	}
	return c
}

pub fn (c &Control) set_cursor(cursor string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.custom_cursor = cursor
	}
	return c
}

pub fn (c &Control) set_font_size(size int) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.font_size = size
	}
	return c
}

pub fn (c &Control) set_font_bold(bold bool) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.font_bold = bold
	}
	return c
}

pub fn (c &Control) set_font_name(font_name string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.font_name = font_name
	}
	return c
}

pub fn (c &Control) set_text_align(align string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.text_align = align
	}
	return c
}

pub fn (c &Control) set_bg_color(color string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.bg_color = color
	}
	return c
}

pub fn (c &Control) set_font_color(color string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.font_color = color
	}
	return c
}

pub fn (c &Control) set_accent_color(color string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.accent_color = color
	}
	return c
}

pub fn (c &Control) set_border(width f32, color string) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.border_width = width
		ptr.border_color = color
	}
	return c
}

pub fn (c &Control) set_corner_radius(radius f32) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.corner_radius = radius
	}
	return c
}

pub fn (c &Control) set_opacity(opacity f64) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.opacity = opacity
	}
	return c
}

pub fn (c &Control) set_visible(visible bool) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.visible = visible
	}
	return c
}

pub fn (c &Control) set_enabled(enabled bool) &Control {
	unsafe {
		mut ptr := &Control(c)
		ptr.disabled = !enabled
	}
	return c
}
