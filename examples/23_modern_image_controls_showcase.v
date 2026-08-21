module main

import simplegui

fn main() {
	// Create high-resolution window (1140 x 560)
	mut win := simplegui.new_simple_window('Modern Image Controls Showcase - SimpleGUI', 1140, 560)
	win.set_theme('Apple Dark')

	// 2. Main Tabbed Navigation Container
	win.begin_tab_container('img_tabs', [
		'Developer Hub & Profiles',
		'Media & Visual Gallery',
		'Workstation & Products',
	])

	// =========================================================================
	// TAB 1: Developer Hub & Profiles
	// =========================================================================
	win.begin_tab_page('page_dev_hub', 0)

	// Top Hero Banner
	win.add_hero_banner(
		'hero_cloud',
		'assets/images/banner_cloud_devops.jpg',
		'Cloud Infrastructure & DevOps Suite',
		'Deploy distributed microservices, inspect live telemetry streams, and manage clusters with native 60 FPS performance.',
		'[Launch Cluster]'
	)

	// Developer Profile Cards in a side-by-side balanced row
	win.begin_row('profiles_row')
	win.add_user_profile_card(
		'prof_ada',
		'assets/images/avatar_ada_lovelace.jpg',
		'Ada Lovelace',
		'@ada_lovelace',
		'Lead Systems Architect',
		'Pioneering computing visionary & low-level compiler optimization.',
		true,
		'[Connect]'
	)
	win.add_user_profile_card(
		'prof_alex',
		'assets/images/avatar_alex_chen.jpg',
		'Alex Chen',
		'@alex_dev',
		'Senior Staff SRE',
		'High-concurrency cloud distributed pipelines and real-time sockets.',
		true,
		'[Message]'
	)
	win.end_row()

	// 3D App / Tool Launcher Tiles Row
	win.add_heading('Developer Quick Launcher')
	win.begin_row('launchers_row')
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
	win.add_app_launcher_tile(
		'tool_cli',
		'assets/images/icon_terminal_cli.jpg',
		'DevStudio CLI v2.0',
		'Interactive Shell & Debugger',
		'READY'
	)
	win.end_row()

	win.end_tab_page()

	// =========================================================================
	// TAB 2: Media & Visual Gallery
	// =========================================================================
	win.begin_tab_page('page_media_gallery', 1)

	// Interactive Multi-Image Showcase Gallery
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
	win.add_image_gallery('showcase_gallery', gallery_images, gallery_captions, 0)

	// Audio & Podcast Player Card
	win.add_heading('Now Playing Audio')
	win.add_media_player(
		'synthwave_player',
		'assets/images/cover_lofi_beats.jpg',
		'Lo-Fi Code & Beats (Synthwave Journey)',
		'Cybernetic Waves Presents - 198X High-Fidelity Stereo',
		240,
		78,
		true
	)

	win.end_tab_page()

	// =========================================================================
	// TAB 3: Workstation & Products
	// =========================================================================
	win.begin_tab_page('page_products', 2)

	win.begin_row('products_row')
	win.add_product_card(
		'prod_mech_keyboard',
		'assets/images/product_dev_station.jpg',
		'Custom Macro Station',
		'Premium mechanical keyboard with walnut finish & RGB underglow',
		'$189.00',
		'BESTSELLER',
		'[Buy Now]'
	)
	win.add_product_card(
		'prod_ai_studio',
		'assets/images/banner_ai_code_studio.jpg',
		'AI Code Studio Pro',
		'Neural assistant with automated code generation & diagnostics',
		'$29 / mo',
		'PRO',
		'[Start Trial]'
	)
	win.add_image_box('sec_preview', 'assets/images/banner_cyber_security.jpg', 320, 270)
	win.end_row()

	win.end_tab_page()

	win.end_tab_container()

	// =========================================================================
	// Interactive Event Handlers
	// =========================================================================

	win.on_click('prof_ada', fn (mut win simplegui.SimpleWindow) {
		win.show_toast('Profile Action', 'Opened communication channel with Ada Lovelace')
	})

	win.on_click('prof_alex', fn (mut win simplegui.SimpleWindow) {
		win.show_toast('Direct Message', 'Starting direct message thread with Alex Chen')
	})

	win.on_click('tool_db', fn (mut win simplegui.SimpleWindow) {
		win.show_toast('App Launcher', 'Connected to Cyber DB Engine cluster (latency: 1.2ms)')
	})

	win.on_click('tool_deploy', fn (mut win simplegui.SimpleWindow) {
		win.show_toast('Cloud Deploy', 'Triggered automated canary deployment pipeline')
	})

	win.on_click('tool_cli', fn (mut win simplegui.SimpleWindow) {
		win.show_toast('Terminal Launched', 'Opening interactive DevStudio CLI session')
	})

	win.on_click('showcase_gallery', fn (mut win simplegui.SimpleWindow) {
		ctrl := win.control('showcase_gallery')
		caption := if ctrl.int_value < ctrl.items_selected.len { ctrl.items_selected[ctrl.int_value] } else { '' }
		win.show_toast('Gallery Slide', 'Viewing: ${caption}')
	})

	win.on_click('synthwave_player', fn (mut win simplegui.SimpleWindow) {
		ctrl := win.control('synthwave_player')
		st := if ctrl.bool_value { 'Playing' } else { 'Paused' }
		win.show_toast('Audio Player', 'Status: ${st} | Lo-Fi Code & Beats')
	})

	win.on_click('prod_mech_keyboard', fn (mut win simplegui.SimpleWindow) {
		win.show_toast('Checkout', 'Added Custom Macro Station ($189.00) to cart!')
	})

	win.on_click('prod_ai_studio', fn (mut win simplegui.SimpleWindow) {
		win.show_toast('Subscription', 'Starting 14-day free trial of AI Code Studio Pro')
	})

	win.on_click('hero_cloud', fn (mut win simplegui.SimpleWindow) {
		win.show_toast('Hero Action', 'Launching Cybernetic Cloud Infrastructure...')
	})

	// Run Application
	win.run()
}
