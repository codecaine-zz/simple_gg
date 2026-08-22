module main

import simplecli

fn main() {
	mut app := simplecli.new_app('say-cli', '1.0.0')
	app.set_description('Text-to-Speech (TTS) Speech Synthesis & Audio Export CLI')

	app.add_flag_string('text', 't', '', 'Text sentence to speak aloud')
	app.add_flag_string('voice', 'v', '', 'Voice name (e.g. Samantha, Alex, Victoria, Fred)')
	app.add_flag_string('rate', 'r', '175', 'Speech rate speed in words per minute')
	app.add_flag_string('output', 'o', '', 'Export speech audio to AIFF/WAV file')
	app.add_flag_bool('list-voices', 'l', false, 'List available native system voices')
	app.add_flag_bool('interactive', 'x', false, 'Launch interactive TTS speech workbench')

	app.parse_cli() or { return }

	app.banner('Say Studio CLI', 'v1.0.0 - Speech Synthesis & Voice Engine')

	if app.get_flag_bool('list-voices') {
		app.info('Available system speech voices:')
		out, _ := app.exec('say -v ? 2>/dev/null')
		println(out)
		return
	}

	if app.get_flag_bool('interactive') {
		run_interactive(mut app)
		return
	}

	text := app.get_flag_string('text')
	if text.len == 0 {
		app.warn('No text provided. Run with -t "Hello World" or -x for interactive mode.')
		app.print_help()
		return
	}

	voice := app.get_flag_string('voice')
	rate := app.get_flag_string('rate')
	out_audio := app.get_flag_string('output')

	mut args := [text]
	if voice.len > 0 {
		args << ['-v', voice]
	}
	if rate.len > 0 {
		args << ['-r', rate]
	}
	if out_audio.len > 0 {
		args << ['-o', out_audio]
	}

	app.info('Speaking text...')
	app.reset_timer()
	app.exec_safe('say', args)
	app.success('Spoken in ${app.elapsed_ms()} ms.')
}

fn run_interactive(mut app simplecli.SimpleCli) {
	app.panel('Say Speech Synthesizer', 'Test text-to-speech voices and export voiceovers.')
	phrase := app.prompt('Enter phrase to speak', 'Welcome to the SimpleGUI headless console environment.')
	voice := app.select('Select voice profile:', ['Samantha', 'Alex', 'Victoria', 'Fred'])
	app.speak_with_voice(phrase, voice)
	app.success('Spoken using ${voice}.')
}
