module main

import simplecli

fn main() {
	mut app := simplecli.new_app('dataconvert-cli', '1.0.0')
	app.set_description('Data Format Converter & Transformer CLI (CSV, TSV, JSON, TOML)')

	app.add_flag_string('input', 'i', '', 'Input data file path')
	app.add_flag_string('output', 'o', '', 'Output data file path (optional, prints to stdout if omitted)')
	app.add_flag_string('from', 'f', 'csv', 'Source format (csv, tsv, json, toml)')
	app.add_flag_string('to', 't', 'json', 'Target format (csv, tsv, json, pretty-json)')
	app.add_flag_bool('interactive', 'x', false, 'Run in interactive conversion mode')

	app.parse_cli() or { return }

	app.banner('Data Format Converter CLI', 'v1.0.0 - Multi-Format RAD Transformer')

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	input_path := app.get_flag_string('input')
	if input_path.len == 0 {
		app.warn('No input file specified. Run with -i <file> or -x for interactive mode.')
		app.print_help()
		return
	}

	if !app.file_exists(input_path) {
		app.error('Input file not found: ${input_path}')
		return
	}

	from_fmt := app.get_flag_string('from').to_lower()
	to_fmt := app.get_flag_string('to').to_lower()
	out_path := app.get_flag_string('output')

	raw_content := app.read_file(input_path)
	app.info('Read ${raw_content.len} bytes from ${input_path}')

	result := convert_data(mut app, raw_content, from_fmt, to_fmt)
	if result.len == 0 {
		return
	}

	if out_path.len > 0 {
		app.write_file(out_path, result)
		app.success('Successfully converted and saved to: ${out_path}')
	} else {
		app.success('Conversion result (${to_fmt}):')
		println(result)
	}
}

fn convert_data(mut app simplecli.SimpleCli, content string, from_fmt string, to_fmt string) string {
	app.reset_timer()
	if from_fmt == 'csv' || from_fmt == 'tsv' {
		delim := if from_fmt == 'tsv' { '\t' } else { ',' }
		lines := content.split_into_lines().filter(it.trim_space().len > 0)
		if lines.len == 0 {
			app.error('Input content is empty')
			return ''
		}

		headers := lines[0].split(delim).map(it.trim_space())
		mut rows_json := []string{}

		for i in 1 .. lines.len {
			cols := lines[i].split(delim).map(it.trim_space())
			mut obj_fields := []string{}
			for j in 0 .. headers.len {
				val := if j < cols.len { cols[j] } else { '' }
				obj_fields << '"${headers[j]}": "${val}"'
			}
			rows_json << '  {' + obj_fields.join(', ') + '}'
		}

		json_str := '[\n' + rows_json.join(',\n') + '\n]'
		if to_fmt == 'pretty-json' || to_fmt == 'json' {
			app.info('Converted ${lines.len - 1} records in ${app.elapsed_ms()} ms')
			return json_str
		}
	} else if from_fmt == 'json' {
		if to_fmt == 'pretty-json' {
			return app.json_pretty(content)
		}
	}

	return content
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Interactive Converter', 'Easily convert between tabular data (CSV, TSV) and JSON objects.')
	from_choice := app.select('Select source format:', ['CSV', 'TSV', 'JSON'])
	to_choice := app.select('Select target format:', ['JSON', 'Pretty-JSON', 'Raw Text'])
	sample_data := 'name,role,department\nAlice,Senior Engineer,DevOps\nBob,Security Lead,Infra\nCharlie,Product Manager,Core'
	app.info('Using sample CSV dataset:\n${sample_data}')
	res := convert_data(mut app, sample_data, from_choice.to_lower(), to_choice.to_lower())
	app.success('Result:')
	println(res)
}
