module main

import simplegui
import os
import time

// -----------------------------------------------------------------------------
// Voice Information Struct
// -----------------------------------------------------------------------------
struct VoiceInfo {
	name        string
	lang        string
	description string
}

// -----------------------------------------------------------------------------
// Speech Recipe Struct
// -----------------------------------------------------------------------------
struct SpeechRecipe {
	title       string
	category    string
	voice       string
	rate        string
	script      string
	description string
}

// get_installed_voices parses `say -v '?'` into a structured list
fn get_installed_voices() []VoiceInfo {
	res := simplegui.exec_safe('say', ['-v', '?'])
	if res.exit_code != 0 || res.output.trim_space() == '' {
		// Fallback standard macOS voices if command fails
		return [
			VoiceInfo{ name: 'Samantha', lang: 'en_US', description: 'Hello! My name is Samantha.' },
			VoiceInfo{ name: 'Alex', lang: 'en_US', description: 'Most people recognize me by my voice.' },
			VoiceInfo{ name: 'Daniel', lang: 'en_GB', description: 'Hello! My name is Daniel.' },
			VoiceInfo{ name: 'Karen', lang: 'en_AU', description: 'Hello! My name is Karen.' },
			VoiceInfo{ name: 'Fred', lang: 'en_US', description: 'I sure like being inside this fancy computer.' },
			VoiceInfo{ name: 'Victoria', lang: 'en_US', description: 'Isn\'t it nice to have a computer that will talk to you?' },
			VoiceInfo{ name: 'Zarvox', lang: 'en_US', description: 'That is not a bug; it is an undocumented feature.' },
			VoiceInfo{ name: 'Trinoids', lang: 'en_US', description: 'We cannot be defeated.' },
			VoiceInfo{ name: 'Whisper', lang: 'en_US', description: 'Psssssst! I can speak in a whisper.' },
		]
	}

	mut list := []VoiceInfo{}
	lines := res.output.split_into_lines()
	for l in lines {
		trimmed := l.trim_space()
		if trimmed == '' { continue }
		
		// Format: "Name                lang_code    # Description"
		parts := trimmed.split('#')
		desc := if parts.len > 1 { parts[1].trim_space() } else { '' }
		
		left := parts[0].trim_space()
		tokens := left.split(' ')
		if tokens.len >= 2 {
			lang := tokens[tokens.len - 1].trim_space()
			mut name_parts := tokens[..tokens.len - 1].clone()
			mut name := name_parts.join(' ').trim_space()
			for name.contains('  ') {
				name = name.replace('  ', ' ')
			}
			if name != '' && lang != '' {
				list << VoiceInfo{
					name: name
					lang: lang
					description: desc
				}
			}
		}
	}
	return list
}

// Built-in speech voiceover recipes
fn get_speech_recipes() []SpeechRecipe {
	return [
		SpeechRecipe{
			title: ' Professional Studio Narration'
			category: 'Voiceover'
			voice: 'Samantha'
			rate: '175'
			script: 'Welcome to the future of native desktop applications. SimpleGUI delivers fast, beginner-friendly Cocoa user interfaces with compiled performance.'
			description: 'Clear, engaging, professional voiceover ideal for product walkthroughs and tutorials.'
		},
		SpeechRecipe{
			title: ' Sci-Fi Cybernetic Robot'
			category: 'Novelty'
			voice: 'Zarvox'
			rate: '160'
			script: 'System diagnostic complete. Neural pathways operational. Quantum processing cores running at maximum efficiency. All systems nominal.'
			description: 'Iconic mechanical synthesized robot cadence for games and sci-fi audio effects.'
		},
		SpeechRecipe{
			title: ' Airport & Transit Station Announcement'
			category: 'Broadcast'
			voice: 'Daniel'
			rate: '155'
			script: 'Attention passengers on Flight 842 to London Heathrow. Immediate boarding is now commencing at Gate B22. Please have your boarding pass and passport ready.'
			description: 'Formal, deliberate public address announcement.'
		},
		SpeechRecipe{
			title: ' Emergency Public Safety Alert'
			category: 'Alert'
			voice: 'Alex'
			rate: '190'
			script: 'Emergency alert. Severe weather warning issued for your immediate region. Seek shelter inside a sturdy building immediately. Do not stay near windows.'
			description: 'High-priority emergency broadcast alert.'
		},
		SpeechRecipe{
			title: ' Classic Audiobook Storyteller'
			category: 'Narration'
			voice: 'Karen'
			rate: '165'
			script: 'It was a bright cold day in April, and the clocks were striking thirteen. Winston Smith, his chin nuzzled into his breast in an effort to escape the vile wind, slipped quickly through the glass doors.'
			description: 'Smooth, measured pacing tailored for literature and long-form storytelling.'
		},
		SpeechRecipe{
			title: ' Podcast Episode Intro & Hook'
			category: 'Media'
			voice: 'Samantha'
			rate: '185'
			script: 'What is up, everyone! Welcome back to Episode 42 of The Developer Horizon. Today, we are tearing down modern desktop frameworks and building lightning fast GUI apps in V.'
			description: 'Dynamic, upbeat pacing for podcast openers and media content.'
		},
		SpeechRecipe{
			title: ' Calm Whisper & Meditation'
			category: 'Novelty'
			voice: 'Whisper'
			rate: '130'
			script: 'Take a deep breath in... hold it for three seconds... and slowly exhale. Let go of all tension and relax your mind.'
			description: 'Soft whisper voice ideal for ambient soundscapes and sleep guides.'
		},
		SpeechRecipe{
			title: ' Rocket Launch Countdown (10 to 1)'
			category: 'Broadcast'
			voice: 'Alex'
			rate: '140'
			script: 'Ten... Nine... Eight... Seven... Six... Five... Four... Three... Two... One... Liftoff! We have liftoff!'
			description: 'Dramatic second-by-second countdown.'
		},
		SpeechRecipe{
			title: ' Terminal Build Finished Chime'
			category: 'Developer'
			voice: 'Victoria'
			rate: '180'
			script: 'Build succeeded! Zero errors, zero warnings. All test suites passed in 3.4 seconds.'
			description: 'Quick developer workstation build chime notification.'
		},
		SpeechRecipe{
			title: ' Retro Arcade Computer'
			category: 'Novelty'
			voice: 'Trinoids'
			rate: '150'
			script: 'Insert coin to continue. Player one ready. High score recorded in mainframe memory.'
			description: 'Nostalgic 80s arcade synthesized speech.'
		}
	]
}

fn main() {
	println('Starting SimpleGUI - Say Studio Pro (macOS Native Speech Synthesizer)...')

	mut win := simplegui.new_simple_window('Say Studio Pro -- macOS Native Speech Synthesizer', 980, 780)
	win.set_fullscreen(true)
	win.restore_saved_theme()
	win.set_padding(18)
	win.set_spacing(10)

	all_voices := get_installed_voices()
	all_recipes := get_speech_recipes()

	// -------------------------------------------------------------
	// Header & Theme Control Bar
	// -------------------------------------------------------------
	win.begin_row('row_header')
	win.add_heading('Say Studio Pro')

	saved_theme := simplegui.get_saved_theme()
	win.add_dropdown('dd_theme_selector', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_theme_selector', 200)
	win.end_row()

	// -------------------------------------------------------------
	// Voice Selection & Tuning Panel
	// -------------------------------------------------------------
	win.begin_group_box('grp_voice_settings', 'Voice & Acoustic Tuning')

	mut voice_titles := []string{}
	for v in all_voices {
		desc := if v.description != '' { ' -- "${v.description}"' } else { '' }
		voice_titles << '${v.name} (${v.lang})${desc}'
	}
	if voice_titles.len == 0 {
		voice_titles = ['Samantha (en_US)', 'Alex (en_US)', 'Daniel (en_GB)', 'Fred (en_US)']
	}

	win.begin_row('row_voice_picker')
	win.add_label('lbl_voice', 'Active Voice:')
	win.add_dropdown('dd_voice', voice_titles, voice_titles[0])
	win.set_control_width('dd_voice', 420)
	win.add_button('btn_preview_voice', 'Preview Voice')
	win.add_button('btn_browse_file', 'Load Text File...')
	win.end_row()

	win.begin_row('row_rate_pitch')
	win.add_label('lbl_rate', 'Speech Rate (WPM):')
	win.add_input('txt_rate', '175')
	win.set_control_width('txt_rate', 70)
	win.add_button('btn_rate_slow', '130 WPM')
	win.add_button('btn_rate_normal', '175 WPM (Default)')
	win.add_button('btn_rate_fast', '230 WPM')

	win.add_label('lbl_format', 'Export Format:')
	formats := ['m4a (AAC Audio)', 'aiff (Uncompressed AIFF)', 'wav (Wave Audio)', 'caf (Core Audio)']
	win.add_dropdown('dd_format', formats, formats[0])
	win.set_control_width('dd_format', 170)
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Speech Recipe & Preset Library
	// -------------------------------------------------------------
	win.begin_group_box('grp_recipes', 'Production Voiceover & Speech Recipes')
	mut recipe_options := ['-- Select a Voiceover Recipe --']
	for r in all_recipes {
		recipe_options << '[${r.category}] ${r.title}'
	}

	win.begin_row('row_recipe_bar')
	win.add_label('lbl_rec_sel', 'Template:')
	win.add_dropdown('dd_recipe', recipe_options, recipe_options[0])
	win.set_control_width('dd_recipe', 480)
	win.add_button('btn_apply_recipe', 'Load Recipe')
	win.add_button('btn_speak_recipe_now', 'Load & Speak Now')
	win.end_row()

	win.begin_row('row_rec_desc')
	win.add_label('lbl_recipe_desc', 'Tip: Select a recipe above to instantly test synthesized voices and narrative pacing.')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Script Editor Pane
	// -------------------------------------------------------------
	win.begin_group_box('grp_script_editor', 'Speech Script & Text Editor (Direct Synthesizer Input)')
	default_script := 'Welcome to SimpleGUI Say Studio Pro! You can synthesize natural sounding voices, tune speech rates, and export voiceovers directly to high-quality audio files.'
	win.add_textarea('txt_script', default_script)
	win.set_control_height('txt_script', 140)
	win.end_group_box()

	// -------------------------------------------------------------
	// Action Execution Toolbar
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_speak', 'Speak Aloud (Synthesize)')
	win.add_button('btn_stop_speech', 'Stop / Cancel')
	win.add_button('btn_export_audio', 'Export Audio to File...')
	win.add_button('btn_copy_cmd', 'Copy CLI Command')
	win.add_button('btn_clear_script', 'Clear Editor')
	win.end_row()

	// -------------------------------------------------------------
	// Status & Activity Log Console
	// -------------------------------------------------------------
	win.begin_group_box('grp_log', 'Synthesis Log & Audio Engine Output')
	win.add_console('say_console', 120)
	win.end_group_box()

	win.begin_row('row_stats')
	win.add_label('lbl_stats', 'Status: Ready  |  Words: 24  |  Characters: 153  |  Estimated Time: ~8.2s')
	win.end_row()

	win.append_console('say_console', ' Say Studio Pro initialized. Found ${all_voices.len} installed native macOS voices.\n', 1)

	// Helper to extract clean voice name
	get_selected_voice := fn (win simplegui.SimpleWindow) string {
		v_full := win.get('dd_voice')
		mut name := v_full.all_before(' (').trim_space()
		if name == '' { name = 'Samantha' }
		return name
	}

	// Helper to calculate speech stats
	update_stats := fn (mut win simplegui.SimpleWindow) {
		text := win.get('txt_script')
		words := text.split_into_lines().join(' ').split(' ').filter(it.trim_space() != '').len
		chars := text.len
		rate_str := win.get('txt_rate').trim_space()
		rate_val := rate_str.f64()
		wpm := if rate_val > 50.0 { rate_val } else { 175.0 }
		est_sec := (f64(words) / wpm) * 60.0

		win.set('lbl_stats', ' Status: Ready  |  Words: ${words}  |  Characters: ${chars}  |  Estimated Time: ~${est_sec:.1f}s')
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Theme Switching
	win.on_change('dd_theme_selector', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})

	// Rate preset buttons
	win.on_click('btn_rate_slow', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_rate', '130')
		w.toast('Rate set to 130 WPM (Slow / Deliberate).')
	})
	win.on_click('btn_rate_normal', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_rate', '175')
		w.toast('Rate set to 175 WPM (Default).')
	})
	win.on_click('btn_rate_fast', fn (mut w simplegui.SimpleWindow) {
		w.set('txt_rate', '230')
		w.toast('Rate set to 230 WPM (Fast / Upbeat).')
	})

	// Preview Voice
	win.on_click('btn_preview_voice', fn [all_voices, get_selected_voice] (mut w simplegui.SimpleWindow) {
		voice := get_selected_voice(w)
		mut sample_text := 'Hello! I am ${voice}, ready to synthesize your text.'
		for v in all_voices {
			if v.name == voice && v.description != '' {
				sample_text = v.description
				break
			}
		}

		rate := w.get('txt_rate').trim_space()
		w.append_console('say_console', ' Previewing voice "${voice}" at ${rate} WPM...\n', 1)
		w.set_status('Speaking voice sample...')
		w.toast('Previewing ${voice}...')

		go fn [mut w, voice, rate, sample_text] () {
			mut args := ['-v', voice]
			if rate != '' && rate != '175' {
				args << ['-r', rate]
			}
			args << sample_text
			simplegui.exec_safe('say', args)
			w.run_on_main_thread(fn (mut win_main simplegui.SimpleWindow) {
				win_main.set_status('Voice preview completed.')
			})
		}()
	})

	// Load Text File from disk
	win.on_click('btn_browse_file', fn [update_stats] (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' && os.exists(path) {
			content := os.read_file(path) or { '' }
			w.set('txt_script', content)
			w.append_console('say_console', ' Loaded document from: ${path} (${content.len} bytes)\n', 1)
			w.toast('Loaded ${os.file_name(path)}')
			update_stats(mut w)
		}
	})

	// Clear Script
	win.on_click('btn_clear_script', fn [update_stats] (mut w simplegui.SimpleWindow) {
		w.set('txt_script', '')
		w.toast('Script cleared.')
		update_stats(mut w)
	})

	// Recipe Selection Change
	win.on_change('dd_recipe', fn [all_recipes] (mut w simplegui.SimpleWindow, selected string) {
		for r in all_recipes {
			if selected.contains(r.title) {
				w.set('lbl_recipe_desc', 'Tip: ' + r.description)
				break
			}
		}
	})

	// Apply Recipe
	win.on_click('btn_apply_recipe', fn [all_recipes, all_voices, update_stats] (mut w simplegui.SimpleWindow) {
		selected := w.get('dd_recipe')
		for r in all_recipes {
			if selected.contains(r.title) {
				w.set('txt_script', r.script)
				w.set('txt_rate', r.rate)
				w.set('lbl_recipe_desc', 'Tip: ' + r.description)
				
				// Select voice in dropdown
				for v in all_voices {
					if v.name == r.voice {
						desc := if v.description != '' { ' -- "${v.description}"' } else { '' }
						w.set_text('dd_voice', '${v.name} (${v.lang})${desc}')
						break
					}
				}
				w.toast('Loaded recipe: ' + r.title)
				update_stats(mut w)
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Speak Aloud (Async Non-Blocking Engine)
	win.on_click('btn_speak', fn [get_selected_voice, update_stats] (mut w simplegui.SimpleWindow) {
		script := w.get('txt_script').trim_space()
		if script == '' {
			w.alert('Script Empty', 'Please enter text or load a recipe to synthesize.')
			return
		}

		voice := get_selected_voice(w)
		rate := w.get('txt_rate').trim_space()

		w.append_console('say_console', ' Starting speech synthesis with voice "${voice}" (${rate} WPM)...\n', 1)
		w.set_status('Speaking script aloud in background...')
		w.toast('Synthesizing speech...')
		update_stats(mut w)

		go fn [mut w, voice, rate, script] () {
			t0 := time.ticks()
			tmp_file := os.join_path(os.temp_dir(), 'say_studio_input_${time.ticks()}.txt')
			os.write_file(tmp_file, script) or {}

			mut raw_args := ['-v', voice]
			if rate != '' && rate != '175' {
				raw_args << ['-r', rate]
			}
			raw_args << ['-f', tmp_file]

			res := simplegui.exec_safe('say', raw_args)
			elapsed_ms := time.ticks() - t0

			if os.exists(tmp_file) {
				os.rm(tmp_file) or {}
			}

			w.run_on_main_thread(fn [res, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('say_console', ' Speech synthesis completed in ${elapsed_ms} ms.\n', 4)
					win_main.set_status('Speech playback finished.')
					win_main.toast('Speech playback finished!')
				} else {
					win_main.append_console('say_console', ' Speech synthesis error:\n' + res.output + '\n', 3)
					win_main.set_status('Error during speech synthesis.')
				}
			})
		}()
	})

	// Load & Speak Recipe Immediately
	win.on_click('btn_speak_recipe_now', fn [all_recipes, all_voices, update_stats] (mut w simplegui.SimpleWindow) {
		selected := w.get('dd_recipe')
		for r in all_recipes {
			if selected.contains(r.title) {
				w.set('txt_script', r.script)
				w.set('txt_rate', r.rate)
				w.set('lbl_recipe_desc', 'Tip: ' + r.description)
				
				for v in all_voices {
					if v.name == r.voice {
						desc := if v.description != '' { ' -- "${v.description}"' } else { '' }
						w.set_text('dd_voice', '${v.name} (${v.lang})${desc}')
						break
					}
				}
				update_stats(mut w)

				voice := r.voice
				rate := r.rate
				script := r.script

				w.append_console('say_console', ' Speaking recipe "${r.title}" (${voice}, ${rate} WPM)...\n', 1)
				w.set_status('Speaking recipe...')
				w.toast('Synthesizing recipe...')

				go fn [mut w, voice, rate, script] () {
					tmp_file := os.join_path(os.temp_dir(), 'say_studio_input_${time.ticks()}.txt')
					os.write_file(tmp_file, script) or {}

					mut raw_args := ['-v', voice]
					if rate != '' && rate != '175' {
						raw_args << ['-r', rate]
					}
					raw_args << ['-f', tmp_file]

					res := simplegui.exec_safe('say', raw_args)
					if os.exists(tmp_file) { os.rm(tmp_file) or {} }

					w.run_on_main_thread(fn [res] (mut win_main simplegui.SimpleWindow) {
						if res.exit_code == 0 {
							win_main.append_console('say_console', ' Speech finished.\n', 4)
							win_main.set_status('Speech finished.')
						}
					})
				}()
				return
			}
		}
		w.toast('Please select a recipe from the dropdown.')
	})

	// Stop / Cancel Speech
	win.on_click('btn_stop_speech', fn (mut w simplegui.SimpleWindow) {
		w.append_console('say_console', ' Cancelling speech output (killall say)...\n', 2)
		simplegui.exec_safe('killall', ['say'])
		w.set_status('Speech playback stopped.')
		w.toast('Speech stopped.')
	})

	// Export Audio to File (M4A / AIFF / WAV)
	win.on_click('btn_export_audio', fn [get_selected_voice] (mut w simplegui.SimpleWindow) {
		script := w.get('txt_script').trim_space()
		if script == '' {
			w.alert('Script Empty', 'Please provide text to export to audio.')
			return
		}

		out_path := w.save_file_picker()
		if out_path == '' { return }

		voice := get_selected_voice(w)
		rate := w.get('txt_rate').trim_space()
		fmt_sel := w.get('dd_format')

		mut ext := '.m4a'
		if fmt_sel.contains('aiff') { ext = '.aiff' }
		else if fmt_sel.contains('wav') { ext = '.wav' }
		else if fmt_sel.contains('caf') { ext = '.caf' }

		mut final_out := out_path
		if !final_out.ends_with(ext) {
			final_out += ext
		}

		w.append_console('say_console', ' Exporting speech audio to: ${final_out}...\n', 1)
		w.set_status('Exporting speech to audio file...')
		w.toast('Exporting audio...')

		go fn [mut w, voice, rate, script, final_out] () {
			t0 := time.ticks()
			tmp_file := os.join_path(os.temp_dir(), 'say_studio_export_${time.ticks()}.txt')
			os.write_file(tmp_file, script) or {}

			mut raw_args := ['-v', voice]
			if rate != '' && rate != '175' {
				raw_args << ['-r', rate]
			}
			raw_args << ['-f', tmp_file]
			raw_args << ['-o', final_out]

			res := simplegui.exec_safe('say', raw_args)
			elapsed_ms := time.ticks() - t0

			if os.exists(tmp_file) { os.rm(tmp_file) or {} }

			w.run_on_main_thread(fn [res, final_out, elapsed_ms] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 && os.exists(final_out) {
					sz := os.file_size(final_out)
					mb := f64(sz) / (1024.0 * 1024.0)
					win_main.append_console('say_console', ' Audio file exported: ${final_out} (${mb:.2f} MB) in ${elapsed_ms} ms!\n', 4)
					win_main.set_status('Audio file exported successfully.')
					win_main.toast('Exported audio file (${mb:.2f} MB)!')
				} else {
					win_main.append_console('say_console', ' Audio export error:\n' + res.output + '\n', 3)
					win_main.set_status('Error exporting audio.')
				}
			})
		}()
	})

	// Copy CLI Command
	win.on_click('btn_copy_cmd', fn [get_selected_voice] (mut w simplegui.SimpleWindow) {
		script := w.get('txt_script').trim_space()
		voice := get_selected_voice(w)
		rate := w.get('txt_rate').trim_space()

		mut parts := ['say', '-v', simplegui.quote_arg(voice)]
		if rate != '' && rate != '175' {
			parts << '-r ${rate}'
		}
		parts << simplegui.quote_arg(script)
		cmd := parts.join(' ')

		w.copy_to_clipboard(cmd)
		w.append_console('say_console', ' Copied CLI command to clipboard:\n${cmd}\n', 1)
		w.toast('Command copied to clipboard!')
	})

	println('Say Studio Pro configured. Starting event loop...')
	win.run()
}
