module main

import simplecli
import time

fn main() {
	mut app := simplecli.new_app('Developer Studio Setup Wizard', '1.0.0')

	// 1. ASCII Banner
	app.banner('Developer Studio Setup Wizard', 'Interactive RAD Console Toolkit')

	app.info('Welcome to the developer workspace configuration utility.')
	app.println('This tool demonstrates interactive RAD console prompts, tables, and progress bars.\n')

	// 2. Interactive Prompts & Selects
	app.step(1, 'Workspace Configuration')
	project_name := app.prompt('Project name', 'my-v-backend-app')
	app.set_state('project_name', project_name)

	env_choice := app.select('Target deployment environment', [
		'Development (Local)',
		'Staging (Pre-production)',
		'Production (Cluster)',
	])
	app.set_state('environment', env_choice)

	features := app.multi_select('Select enabled service modules', [
		'REST API Server',
		'WebSocket Live Bus',
		'SQLite Persistence',
		'Redis Cache Layer',
		'Automated Metrics & Logging',
	])
	app.set_state('features', features.join(', '))

	is_secured := app.confirm('Enable TLS / HTTPS and Security Headers?', true)
	app.set_state('secured', '${is_secured}')

	// 3. Summary Panel & Review Table
	app.step(2, 'Configuration Review')
	app.panel('Workspace Summary', 
		'Project:     ${project_name}\n' +
		'Environment: ${env_choice}\n' +
		'Security:    ${if is_secured { "TLS Enabled" } else { "Plain HTTP" }}\n' +
		'Modules:     ${features.join(", ")}'
	)

	headers := ['Module Component', 'Target Status', 'Encryption']
	mut rows := [][]string{}
	for feat in features {
		rows << [feat, 'Configured', if is_secured { 'AES-256' } else { 'Disabled' }]
	}
	app.table(headers, rows)

	// 4. Progress Bar Simulation
	app.step(3, 'Scaffolding & Initializing Project Workspace')
	total_steps := 50
	for i in 1 .. (total_steps + 1) {
		app.progress_bar(f64(i), f64(total_steps), 'Generating templates...')
		time.sleep(15 * time.millisecond)
	}

	// 5. State Persistence
	state_file := app.get_system_path('state') + '/setup_wizard_state.json'
	app.save_state(state_file) or {
		app.warn('Could not save state to ${state_file}')
	}

	// 6. Completion & Notification
	app.step(4, 'Ready to Deploy')
	app.success('Setup completed successfully! State saved to: ${state_file}')
	app.notify('Setup Complete', 'Project ${project_name} initialized.')
	app.print_elapsed()
}
