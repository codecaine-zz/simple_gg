module simplegui

fn test_image_box_creation() {
	mut win := new_simple_window('Test Image Box', 800, 600)
	win.add_image_box('img1', 'assets/images/banner_cloud_devops.jpg', 300, 200)

	ctrl := win.control('img1')
	assert ctrl.name == 'img1'
	assert ctrl.kind == 'image_box'
	assert ctrl.text_value == 'assets/images/banner_cloud_devops.jpg'
	assert ctrl.w == 300.0
	assert ctrl.h == 200.0

	// Test nameless shortcut
	win.image_box('assets/images/icon_db_engine.jpg', 64, 64)
	assert win.controls.len == 2
}

fn test_user_profile_card() {
	mut win := new_simple_window('Test Profile Card', 800, 600)
	win.add_user_profile_card(
		'prof_ada',
		'assets/images/avatar_ada_lovelace.jpg',
		'Ada Lovelace',
		'@ada_lovelace',
		'Lead Systems Architect',
		'Pioneering computing visionary and V language enthusiast.',
		true,
		'[Connect]'
	)

	mut ctrl := win.control('prof_ada')
	assert ctrl.name == 'prof_ada'
	assert ctrl.kind == 'user_profile_card'
	assert ctrl.text_value == 'assets/images/avatar_ada_lovelace.jpg'
	assert ctrl.title == 'Ada Lovelace'
	assert ctrl.placeholder == '@ada_lovelace'
	assert ctrl.bool_value == true
	assert ctrl.items.len >= 3
	assert ctrl.items[0] == 'Lead Systems Architect'
	assert ctrl.variant == '[Connect]'

	// Test online status helper
	win.set_user_online_status('prof_ada', false)
	ctrl = win.control('prof_ada')
	assert ctrl.bool_value == false
	assert ctrl.text_value == 'assets/images/avatar_ada_lovelace.jpg'

	// Test method chaining update
	ctrl.set_user_profile(
		'assets/images/avatar_alex_chen.jpg',
		'Alex Chen',
		'@alex_dev',
		'Senior Staff Engineer',
		'Full-stack cloud infrastructure developer.',
		true
	)
	assert ctrl.text_value == 'assets/images/avatar_alex_chen.jpg'
	assert ctrl.title == 'Alex Chen'
	assert ctrl.placeholder == '@alex_dev'
	assert ctrl.bool_value == true
	assert ctrl.items[0] == 'Senior Staff Engineer'
}

fn test_product_card() {
	mut win := new_simple_window('Test Product Card', 800, 600)
	win.add_product_card(
		'prod_keyboard',
		'assets/images/product_dev_station.jpg',
		'Cyber Workstation Pro',
		'Custom mechanical keyboard & macro keypad with RGB underglow',
		'$189.00',
		'BESTSELLER',
		'[Buy Now]'
	)

	mut ctrl := win.control('prod_keyboard')
	assert ctrl.name == 'prod_keyboard'
	assert ctrl.kind == 'product_card'
	assert ctrl.title == 'Cyber Workstation Pro'
	assert ctrl.placeholder.contains('Custom mechanical keyboard')
	assert ctrl.items[0] == '$189.00'
	assert ctrl.items[1] == 'BESTSELLER'
	assert ctrl.items[2] == '[Buy Now]'

	// Method chain update
	ctrl.set_product_info(
		'assets/images/icon_rocket_deploy.jpg',
		'Cloud Deploy Pro',
		'Automated continuous delivery suite',
		'$299.00',
		'FEATURED'
	)
	assert ctrl.title == 'Cloud Deploy Pro'
	assert ctrl.items[0] == '$299.00'
	assert ctrl.items[1] == 'FEATURED'
}

fn test_image_gallery_navigation() {
	mut win := new_simple_window('Test Gallery', 800, 600)
	images := [
		'assets/images/banner_cloud_devops.jpg',
		'assets/images/banner_ai_code_studio.jpg',
		'assets/images/banner_cyber_security.jpg',
	]
	captions := [
		'Cloud Datacenter Infrastructure',
		'AI Code Studio Workstation',
		'Cyber Security Shield Center',
	]

	win.add_image_gallery('gallery1', images, captions, 0)

	mut ctrl := win.control('gallery1')
	assert ctrl.kind == 'image_gallery'
	assert ctrl.items.len == 3
	assert ctrl.items_selected.len == 3
	assert ctrl.int_value == 0

	// Programmatic navigation
	win.next_gallery_image('gallery1')
	ctrl = win.control('gallery1')
	assert ctrl.int_value == 1

	win.next_gallery_image('gallery1')
	ctrl = win.control('gallery1')
	assert ctrl.int_value == 2

	// Wrap around next
	win.next_gallery_image('gallery1')
	ctrl = win.control('gallery1')
	assert ctrl.int_value == 0

	// Wrap around prev
	win.prev_gallery_image('gallery1')
	ctrl = win.control('gallery1')
	assert ctrl.int_value == 2

	// Direct jump
	win.set_gallery_index('gallery1', 1)
	ctrl = win.control('gallery1')
	assert ctrl.int_value == 1
}

fn test_app_launcher_tile() {
	mut win := new_simple_window('Test App Tile', 800, 600)
	win.add_app_launcher_tile(
		'tile_db',
		'assets/images/icon_db_engine.jpg',
		'Cyber DB Engine',
		'Distributed SQL & Key-Value',
		'RUNNING'
	)

	ctrl := win.control('tile_db')
	assert ctrl.name == 'tile_db'
	assert ctrl.kind == 'app_launcher_tile'
	assert ctrl.title == 'Cyber DB Engine'
	assert ctrl.placeholder == 'Distributed SQL & Key-Value'
	assert ctrl.items[0] == 'RUNNING'

	// Nameless shortcut
	win.app_tile('assets/images/icon_terminal_cli.jpg', 'Dev Terminal', 'READY')
	assert win.controls.len == 2
}

fn test_media_player_card() {
	mut win := new_simple_window('Test Media Player', 800, 600)
	win.add_media_player(
		'synth_player',
		'assets/images/cover_lofi_beats.jpg',
		'Lo-Fi Code & Beats',
		'Cybernetic Waves - Synthwave Journeys',
		240,
		65,
		false
	)

	mut ctrl := win.control('synth_player')
	assert ctrl.kind == 'media_player'
	assert ctrl.title == 'Lo-Fi Code & Beats'
	assert ctrl.placeholder == 'Cybernetic Waves - Synthwave Journeys'
	assert ctrl.int_value == 240
	assert ctrl.min_val == 65.0
	assert ctrl.bool_value == false

	// Toggle play
	win.toggle_media_player('synth_player')
	ctrl = win.control('synth_player')
	assert ctrl.bool_value == true

	// Seek progress
	win.set_media_player_progress('synth_player', 120)
	ctrl = win.control('synth_player')
	assert ctrl.min_val == 120.0
}

fn test_hero_banner() {
	mut win := new_simple_window('Test Hero Banner', 800, 600)
	win.add_hero_banner(
		'hero_main',
		'assets/images/banner_cloud_devops.jpg',
		'Supercharge Your Developer Workflow',
		'Build, test, and deploy mission-critical desktop tools at 60 FPS with native Metal acceleration.',
		'[Get Started Now]'
	)

	ctrl := win.control('hero_main')
	assert ctrl.name == 'hero_main'
	assert ctrl.kind == 'hero_banner'
	assert ctrl.title == 'Supercharge Your Developer Workflow'
	assert ctrl.items[0] == '[Get Started Now]'
	assert ctrl.items[2] == 'FEATURED'
}
