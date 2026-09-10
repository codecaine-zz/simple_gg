module main

import cliutils

fn main() {
	println('==================================================')
	println('                demo_cliutils                     ')
	println('==================================================')

	// 1. ANSI Colors & Styling
	println(cliutils.bold(cliutils.cyan('Styled Terminal Output:')))
	println(cliutils.green('  ✔ Success in green'))
	println(cliutils.yellow('  ⚠ Warning in yellow'))
	println(cliutils.red('  ✖ Error in red'))
	println(cliutils.magenta('  ★ Feature in magenta'))
	println(cliutils.gray('  ℹ Debug info in gray'))

	// 2. Visualizations: Sparkline & Gauge
	println('\n' + cliutils.bold('Sparkline (data trend):'))
	println('  ' + cliutils.sparkline([1.0, 3.0, 7.0, 2.0, 8.0, 5.0, 9.0, 4.0]))

	println('\n' + cliutils.bold('Gauge (resource meter):'))
	println('  ' + cliutils.gauge('RAM', 7.5, 10.0, 'GB'))

	// 3. Bar Chart
	println('\n' + cliutils.bold('Horizontal Bar Chart:'))
	bars := cliutils.bar_chart('Performance Metrics', {
		'Throughput': 88.0
		'Cache Hits': 95.5
		'I/O Load':   35.0
	}, 20)
	println(bars)

	// 4. Tree View
	println(cliutils.bold('Tree Hierarchy:'))
	tree := cliutils.TreeNode{
		label: 'vlang_utils'
		children: [
			cliutils.TreeNode{ label: 'fileutils' },
			cliutils.TreeNode{ label: 'sqliteutils' },
			cliutils.TreeNode{
				label: 'cli'
				children: [
					cliutils.TreeNode{ label: 'cliutils' },
					cliutils.TreeNode{ label: 'colorutils' },
				]
			},
		]
	}
	println(cliutils.render_tree(tree))

	// 5. Table Formatting (Markdown)
	println(cliutils.bold('Terminal Table (Markdown):'))
	table := cliutils.table_to_markdown(['Module', 'Category', 'Status'], [
		['fileutils', 'Persistence', 'Active'],
		['sqliteutils', 'Database', 'Active'],
		['cliutils', 'Terminal RAD', 'Active'],
	])
	println(table)

	println('\n✔ cliutils demo completed successfully!')
}
