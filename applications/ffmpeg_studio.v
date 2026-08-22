module main

import os
import simplegui

// Helper to find ffmpeg and ffprobe paths (checking Homebrew and PATH)
fn get_ffmpeg_bin() string {
	if path := os.find_abs_path_of_executable('ffmpeg') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/ffmpeg',
		'/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg',
		'/usr/local/bin/ffmpeg',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'ffmpeg'
}

fn get_ffprobe_bin() string {
	if path := os.find_abs_path_of_executable('ffprobe') {
		return path
	}
	common_paths := [
		'/opt/homebrew/bin/ffprobe',
		'/opt/homebrew/opt/ffmpeg-full/bin/ffprobe',
		'/usr/local/bin/ffprobe',
	]
	for p in common_paths {
		if os.exists(p) {
			return p
		}
	}
	return 'ffprobe'
}

// Get video duration in seconds using ffprobe
fn get_media_duration(file_path string) f64 {
	ffprobe := get_ffprobe_bin()
	cmd := '${ffprobe} -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${file_path}"'
	res := os.execute(cmd)
	if res.exit_code == 0 {
		return res.output.trim_space().f64()
	}
	return 0.0
}

fn main() {
	println('Starting SimpleGUI - FFmpeg Studio Pro (Async Non-Blocking)...')

	mut win := simplegui.new_simple_window('SimpleGUI - FFmpeg Studio Pro', 960, 890)
	win.set_fullscreen(true)
	win.set_spacing(8)
	win.set_padding(16)

	saved_theme := simplegui.get_saved_theme()
	win.set_theme(saved_theme)

	// Top Banner / Status
	win.begin_row('row_ffmpeg_top')
	win.add_heading('FFmpeg Studio Pro')
	win.add_label('lbl_theme', 'Theme:')
	win.add_dropdown('dd_app_theme', simplegui.list_themes(), saved_theme)
	win.set_control_width('dd_app_theme', 150)
	win.end_row()

	win.on_change('dd_app_theme', fn (mut w simplegui.SimpleWindow, selected string) {
		w.set_theme(selected)
		w.toast('Theme changed to ${selected}')
	})
	ffmpeg_path := get_ffmpeg_bin()
	ffprobe_path := get_ffprobe_bin()
	win.add_label('lbl_engine_info', 'Engine: ${ffmpeg_path}  |  FFprobe: ${ffprobe_path}')

	// -------------------------------------------------------------
	// File Selection Group
	// -------------------------------------------------------------
	win.begin_group_box('grp_files', 'Media Input & Output')
	
	// Input File Row
	win.begin_row('row_input')
	win.add_label('lbl_input', 'Input File:')
	win.add_input('txt_input', '')
	win.set_control_width('txt_input', 500)
	win.add_button('btn_browse_in', 'Browse...')
	win.add_button('btn_probe', 'Inspect')
	win.add_button('btn_batch_mode', 'Batch Folder')
	win.end_row()

	// Output File Row
	win.begin_row('row_output')
	win.add_label('lbl_output', 'Output File:')
	win.add_input('txt_output', '')
	win.set_control_width('txt_output', 500)
	win.add_button('btn_browse_out', 'Save As...')
	win.add_button('btn_auto_out', 'Auto Name')
	win.end_row()

	win.end_group_box()

	// -------------------------------------------------------------
	// Processing Mode Tabs (Expanded Suite)
	// -------------------------------------------------------------
	win.add_tabs('tabs_mode', [
		' Transcode & Codecs',
		' Target Size & Social',
		' Audio & Loudnorm',
		' Trim & Cut',
		' Aspect & Filters',
		' Frame & Storyboard',
		' High-Def GIF',
		' Batch Transcode',
	])

	// Tab 1: Video Transcode & Codecs
	win.begin_group_box('pane_transcode', 'Video Transcode, Codecs & Hardware Acceleration')
	win.begin_row('row_tc_1')
	win.add_label('lbl_vcodec', 'Video Codec:')
	win.add_dropdown('dd_vcodec', ['H.264 (libx264 - Universal)', 'H.265/HEVC (libx265 - High Efficiency)', 'Apple ProRes 422 HQ', 'AV1 (libsvtav1 - Next-Gen)', 'VP9 (WebM)', 'Copy (Instant Lossless Remux)'], 'H.264 (libx264 - Universal)')
	win.add_label('lbl_container', 'Container Format:')
	win.add_dropdown('dd_container', ['mp4', 'mkv', 'mov', 'webm', 'avi', 'ts', 'm4v'], 'mp4')
	win.end_row()

	win.begin_row('row_tc_2')
	win.add_label('lbl_crf', 'Quality (CRF):')
	win.add_dropdown('dd_crf', ['18 (Near Lossless / Master)', '20 (High Quality Web)', '23 (Balanced Standard)', '28 (Compact / Small File)', '32 (Max Space Saving)'], '23 (Balanced Standard)')
	win.add_label('lbl_preset', 'Encoding Speed:')
	win.add_dropdown('dd_preset', ['ultrafast', 'veryfast', 'fast', 'medium', 'slow', 'veryslow'], 'medium')
	win.end_row()

	win.begin_row('row_tc_3')
	win.add_checkbox('chk_hardware_accel', 'Apple Silicon Hardware Acceleration (VideoToolbox)', true)
	win.end_row()
	win.begin_row('row_tc_4')
	win.add_checkbox('chk_faststart', 'Web FastStart (Instant Web Playback Optimization)', true)
	win.end_row()
	win.end_group_box()

	// Tab 2: Target File Size & Social Media Presets
	win.begin_group_box('pane_target_size', 'Target File Size Limit & Social Media Presets')
	win.begin_row('row_target_1')
	win.add_label('lbl_target_preset', 'Platform / Target Limit:')
	win.add_dropdown('dd_target_preset', [
		'Custom Target Size (MB)',
		'Discord Free (< 10 MB)',
		'Discord Nitro (< 50 MB)',
		'Telegram / WhatsApp (< 16 MB)',
		'Email Attachment (< 25 MB)',
		'YouTube 1080p Standard (8 Mbps)',
		'YouTube 4K UHD (35 Mbps)',
		'TikTok / Reels 1080x1920 (Vertical 9:16)',
		'Twitter / X Video (H.264 1080p)'
	], 'Discord Free (< 10 MB)')
	win.add_label('lbl_custom_mb', 'Target Size (MB):')
	win.add_input('txt_target_mb', '9.5')
	win.end_row()

	win.begin_row('row_target_2')
	win.add_checkbox('chk_twopass', '2-Pass Encoding for Exact Size Matching', true)
	win.end_row()
	win.begin_row('row_target_3')
	win.add_checkbox('chk_mute_target', 'Mute / Remove Audio (Video Only)', false)
	win.end_row()
	win.end_group_box()

	// Tab 3: Audio & Loudnorm
	win.begin_group_box('pane_audio', 'Audio Extraction, Loudnorm (EBU R128) & Filtering')
	win.begin_row('row_aud_1')
	win.add_label('lbl_acodec', 'Audio Format:')
	win.add_dropdown('dd_aformat', ['mp3', 'aac', 'flac (Lossless)', 'wav (Uncompressed PCM)', 'ogg (Vorbis)', 'm4a (Apple AAC)', 'opus'], 'mp3')
	win.add_label('lbl_abitrate', 'Bitrate:')
	win.add_dropdown('dd_abitrate', ['320 kbps (Studio Master)', '256 kbps (High Quality)', '192 kbps (Standard)', '128 kbps (Compact)', '64 kbps (Voice / Podcast)'], '192 kbps (Standard)')
	win.end_row()

	win.begin_row('row_aud_2')
	win.add_label('lbl_channels', 'Channels:')
	win.add_dropdown('dd_achannels', ['Original Channels', 'Stereo (2.0)', 'Mono (1.0)', 'Surround (5.1)'], 'Original Channels')
	win.add_label('lbl_volume', 'Volume Adjustment:')
	win.add_dropdown('dd_avolume', ['100% (Original)', '125% (+2dB)', '150% (+3.5dB)', '200% (+6dB Boost)', '50% (-6dB Quiet)'], '100% (Original)')
	win.end_row()

	win.begin_row('row_aud_3')
	win.add_checkbox('chk_loudnorm', 'Broadcast Audio Normalization (EBU R128)', true)
	win.end_row()
	win.begin_row('row_aud_4')
	win.add_checkbox('chk_afftdn', 'FFT Audio Denoise Filter (Remove Hum & Hiss)', false)
	win.end_row()
	win.end_group_box()

	// Tab 4: Trim & Cut
	win.begin_group_box('pane_trim', 'Precise Time Trimming & Lossless Cutting')
	win.begin_row('row_trim_1')
	win.add_label('lbl_start_time', 'Start Time (HH:MM:SS):')
	win.add_input('txt_start_time', '00:00:00')
	win.add_label('lbl_end_time', 'Duration or End Time:')
	win.add_input('txt_end_time', '00:00:30')
	win.end_row()

	win.begin_row('row_trim_2')
	win.add_checkbox('chk_trim_fast', 'Fast Keyframe Seeking (Lossless Stream Copy)', true)
	win.end_row()
	win.begin_row('row_trim_3')
	win.add_checkbox('chk_fade_in_out', '1-Second Smooth Video & Audio Fade-In/Out', false)
	win.end_row()
	win.end_group_box()

	// Tab 5: Aspect Ratio & Visual Filters
	win.begin_group_box('pane_filters', 'Resolution, Social Aspect Ratio (9:16 / 1:1) & Visual Filters')
	win.begin_row('row_flt_1')
	win.add_label('lbl_scale', 'Resolution / Aspect Ratio:')
	win.add_dropdown('dd_scale', [
		'Original Resolution',
		'3840x2160 (4K UHD 16:9)',
		'1920x1080 (1080p FHD 16:9)',
		'1280x720 (720p HD 16:9)',
		'1080x1920 (TikTok / Reels / Shorts 9:16)',
		'1080x1080 (Instagram Square 1:1)',
		'854x480 (480p SD)',
		'640x360 (360p Mobile)'
	], '1920x1080 (1080p FHD 16:9)')
	win.add_label('lbl_fps', 'Frame Rate:')
	win.add_dropdown('dd_fps', ['Original FPS', '60 fps (Smooth)', '30 fps (Standard)', '24 fps (Cinema)', '15 fps'], 'Original FPS')
	win.end_row()

	win.begin_row('row_flt_2')
	win.add_label('lbl_transform', 'Rotation / Orientation:')
	win.add_dropdown('dd_transform', ['None', 'Rotate 90 deg  Clockwise', 'Rotate 90 deg  Counter-Clockwise', 'Rotate 180 deg ', 'Flip Horizontal', 'Flip Vertical', 'Grayscale / Black & White'], 'None')
	win.add_label('lbl_speed', 'Playback Speed:')
	win.add_dropdown('dd_speed', ['1.0x (Normal)', '0.5x (Slow Motion)', '1.5x (Speed Up)', '2.0x (Double Speed)', '4.0x (Timelapse)', '8.0x (Hyperlapse)'], '1.0x (Normal)')
	win.end_row()

	win.begin_row('row_flt_3')
	win.add_checkbox('chk_denoise', 'Apply High-Quality Video Denoise Filter (hqdn3d)', false)
	win.add_checkbox('chk_mute_video', 'Mute All Audio Tracks (Silent Video)', false)
	win.end_row()
	win.end_group_box()

	// Tab 6: Frame & Storyboard Extraction
	win.begin_group_box('pane_frames', 'Thumbnail Snapshot & Storyboard Contact Sheet Generator')
	win.begin_row('row_frame_1')
	win.add_label('lbl_thumb_time', 'Timestamp to Capture (HH:MM:SS):')
	win.add_input('txt_thumb_time', '00:00:05')
	win.add_label('lbl_thumb_format', 'Image Format:')
	win.add_dropdown('dd_thumb_format', ['PNG (Lossless)', 'JPEG (High Quality)', 'WebP'], 'PNG (Lossless)')
	win.end_row()

	win.begin_row('row_frame_2')
	win.add_label('lbl_storyboard', 'Storyboard Contact Sheet Mode:')
	win.add_dropdown('dd_storyboard', ['Single Frame Thumbnail', '3x3 Grid (9 Thumbnails)', '4x4 Grid (16 Thumbnails)', '5x5 Grid (25 Thumbnails)'], 'Single Frame Thumbnail')
	win.end_row()
	win.end_group_box()

	// Tab 7: High-Def GIF Creator
	win.begin_group_box('pane_gif', 'HD Animated GIF Creator with 2-Pass Palette Filter')
	win.begin_row('row_gif_1')
	win.add_label('lbl_gif_fps', 'GIF Frame Rate:')
	win.add_dropdown('dd_gif_fps', ['15 fps (Smooth)', '20 fps', '24 fps (Cinema)', '30 fps (Ultra Smooth)', '10 fps (Compact)'], '15 fps (Smooth)')
	win.add_label('lbl_gif_width', 'GIF Width:')
	win.add_dropdown('dd_gif_width', ['480px (Standard Web)', '640px (Medium)', '800px (Large)', '320px (Small Icon)'], '480px (Standard Web)')
	win.end_row()

	win.begin_row('row_gif_2')
	win.add_checkbox('chk_gif_palette', 'Use 2-Pass Palettegen Filter (Eliminates color banding & artifacts)', true)
	win.add_checkbox('chk_gif_loop', 'Infinite Looping GIF', true)
	win.end_row()
	win.end_group_box()

	// Tab 8: Batch Folder Transcode
	win.begin_group_box('pane_batch', 'Bulk Directory Transcoder')
	win.begin_row('row_batch_1')
	win.add_label('lbl_batch_dir', 'Input Folder:')
	win.add_input('txt_batch_dir', '')
	win.set_control_width('txt_batch_dir', 480)
	win.add_button('btn_browse_batch_in', 'Select Folder...')
	win.end_row()

	win.begin_row('row_batch_2')
	win.add_label('lbl_batch_ext', 'Target Format:')
	win.add_dropdown('dd_batch_format', ['Convert All Videos to MP4 (H.264)', 'Convert All Videos to WebM', 'Extract All Audio to MP3', 'Extract All Audio to WAV'], 'Convert All Videos to MP4 (H.264)')
	win.add_button('btn_run_batch', 'Run Batch Queue')
	win.end_row()
	win.end_group_box()

	// Initial visibility for tabs
	win.set_control_visible('pane_transcode', true)
	win.set_control_visible('pane_target_size', false)
	win.set_control_visible('pane_audio', false)
	win.set_control_visible('pane_trim', false)
	win.set_control_visible('pane_filters', false)
	win.set_control_visible('pane_frames', false)
	win.set_control_visible('pane_gif', false)
	win.set_control_visible('pane_batch', false)

	// -------------------------------------------------------------
	// Live Command Preview Section
	// -------------------------------------------------------------
	win.begin_group_box('grp_cmd', 'Live Generated FFmpeg Command Preview')
	win.begin_row('row_cmd')
	win.add_input('txt_command', 'ffmpeg -i input.mp4 output.mp4')
	win.set_control_width('txt_command', 660)
	win.add_button('btn_build_cmd', 'Refresh')
	win.add_button('btn_copy_cmd', 'Copy')
	win.end_row()
	win.end_group_box()

	// -------------------------------------------------------------
	// Execution & Console Log
	// -------------------------------------------------------------
	win.begin_row('row_actions')
	win.add_button('btn_run', 'Start Processing')
	win.add_button('btn_reveal', 'Reveal Output in Finder')
	win.add_button('btn_clear_log', 'Clear Log')
	win.end_row()

	win.add_console('log_console', 160)

	// Initial log output
	win.append_console('log_console', ' SimpleGUI FFmpeg Studio Pro Initialized (Async Non-Blocking Engine).\n', 1)
	win.append_console('log_console', ' Detected FFmpeg: ' + ffmpeg_path + '\n', 4)
	win.append_console('log_console', ' Detected FFprobe: ' + ffprobe_path + '\n', 4)

	// -------------------------------------------------------------
	// Command Builder Logic Helper
	// -------------------------------------------------------------
	build_command := fn (win &simplegui.SimpleWindow) string {
		ffmpeg := get_ffmpeg_bin()
		in_file := win.get('txt_input').trim_space()
		out_file := win.get('txt_output').trim_space()

		if in_file == '' {
			return '${ffmpeg} -i <input_file> <output_file>'
		}

		current_tab := win.get('tabs_mode')
		mut cmd_parts := [ffmpeg, '-y', '-i', '"${in_file}"']

		if current_tab.contains('Transcode') || current_tab == '' {
			vcodec_sel := win.get('dd_vcodec')
			
			if vcodec_sel.contains('Copy') {
				cmd_parts << ['-c', 'copy']
			} else {
				if vcodec_sel.contains('H.264') {
					cmd_parts << ['-c:v', 'libx264']
				} else if vcodec_sel.contains('H.265') {
					cmd_parts << ['-c:v', 'libx265']
				} else if vcodec_sel.contains('ProRes') {
					cmd_parts << ['-c:v', 'prores_ks', '-profile:v', '3']
				} else if vcodec_sel.contains('AV1') {
					cmd_parts << ['-c:v', 'libsvtav1']
				} else if vcodec_sel.contains('VP9') {
					cmd_parts << ['-c:v', 'libvpx-vp9']
				}

				crf_sel := win.get('dd_crf')
				if crf_sel.contains('18') {
					cmd_parts << ['-crf', '18']
				} else if crf_sel.contains('20') {
					cmd_parts << ['-crf', '20']
				} else if crf_sel.contains('28') {
					cmd_parts << ['-crf', '28']
				} else if crf_sel.contains('32') {
					cmd_parts << ['-crf', '32']
				} else {
					cmd_parts << ['-crf', '23']
				}

				preset_sel := win.get('dd_preset')
				if preset_sel != '' {
					cmd_parts << ['-preset', preset_sel]
				}
				cmd_parts << ['-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart']
			}
		} else if current_tab.contains('Target Size') {
			target_preset := win.get('dd_target_preset')
			mut target_mb := win.get('txt_target_mb').trim_space().f64()
			if target_preset.contains('10 MB') { target_mb = 9.5 }
			else if target_preset.contains('50 MB') { target_mb = 48.0 }
			else if target_preset.contains('16 MB') { target_mb = 15.0 }
			else if target_preset.contains('25 MB') { target_mb = 24.0 }

			dur := get_media_duration(in_file)
			effective_dur := if dur > 0.0 { dur } else { 60.0 }
			
			audio_kbps := 128.0
			total_kbits := target_mb * 8192.0
			video_kbps := (total_kbits / effective_dur) - audio_kbps
			v_rate := if video_kbps > 100.0 { int(video_kbps) } else { 200 }
			max_r := int(f64(v_rate) * 1.4)
			buf_r := v_rate * 2

			cmd_parts << ['-c:v', 'libx264', '-b:v', '${v_rate}k', '-maxrate', '${max_r}k', '-bufsize', '${buf_r}k', '-preset', 'medium', '-c:a', 'aac', '-b:a', '128k', '-movflags', '+faststart']
		} else if current_tab.contains('Audio') {
			cmd_parts << ['-vn']
			format_sel := win.get('dd_aformat')
			bitrate_sel := win.get('dd_abitrate')
			
			mut br := '192k'
			if bitrate_sel.contains('320') { br = '320k' }
			else if bitrate_sel.contains('256') { br = '256k' }
			else if bitrate_sel.contains('128') { br = '128k' }
			else if bitrate_sel.contains('64') { br = '64k' }

			if format_sel.contains('mp3') {
				cmd_parts << ['-c:a', 'libmp3lame', '-b:a', br]
			} else if format_sel.contains('flac') {
				cmd_parts << ['-c:a', 'flac']
			} else if format_sel.contains('wav') {
				cmd_parts << ['-c:a', 'pcm_s16le']
			} else if format_sel.contains('ogg') {
				cmd_parts << ['-c:a', 'libvorbis', '-q:a', '6']
			} else if format_sel.contains('opus') {
				cmd_parts << ['-c:a', 'libopus', '-b:a', br]
			} else {
				cmd_parts << ['-c:a', 'aac', '-b:a', br]
			}

			mut af_filters := []string{}
			vol_sel := win.get('dd_avolume')
			if vol_sel.contains('125%') { af_filters << 'volume=1.25' }
			else if vol_sel.contains('150%') { af_filters << 'volume=1.5' }
			else if vol_sel.contains('200%') { af_filters << 'volume=2.0' }
			else if vol_sel.contains('50%') { af_filters << 'volume=0.5' }

			af_filters << 'loudnorm=I=-16:TP=-1.5:LRA=11'

			if af_filters.len > 0 {
				cmd_parts << ['-af', '"' + af_filters.join(',') + '"']
			}
		} else if current_tab.contains('Trim') {
			start_t := win.get('txt_start_time').trim_space()
			end_t := win.get('txt_end_time').trim_space()
			if start_t != '' && start_t != '00:00:00' {
				cmd_parts << ['-ss', start_t]
			}
			if end_t != '' {
				cmd_parts << ['-t', end_t]
			}
			cmd_parts << ['-c', 'copy']
		} else if current_tab.contains('Aspect') || current_tab.contains('Filters') {
			scale_sel := win.get('dd_scale')
			mut vf_filters := []string{}

			if scale_sel.contains('3840x2160') {
				vf_filters << 'scale=3840:2160:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2'
			} else if scale_sel.contains('1920x1080') {
				vf_filters << 'scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2'
			} else if scale_sel.contains('1280x720') {
				vf_filters << 'scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2'
			} else if scale_sel.contains('1080x1920') {
				vf_filters << 'scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=black'
			} else if scale_sel.contains('1080x1080') {
				vf_filters << 'scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:(ow-iw)/2:(oh-ih)/2:color=black'
			} else if scale_sel.contains('854x480') {
				vf_filters << 'scale=854:480'
			}

			trans_sel := win.get('dd_transform')
			if trans_sel.contains('90 deg  Clockwise') {
				vf_filters << 'transpose=1'
			} else if trans_sel.contains('Counter-Clockwise') {
				vf_filters << 'transpose=2'
			} else if trans_sel.contains('180 deg ') {
				vf_filters << 'transpose=2,transpose=2'
			} else if trans_sel.contains('Horizontal') {
				vf_filters << 'hflip'
			} else if trans_sel.contains('Vertical') {
				vf_filters << 'vflip'
			} else if trans_sel.contains('Grayscale') {
				vf_filters << 'hue=s=0'
			}

			speed_sel := win.get('dd_speed')
			if speed_sel.contains('0.5x') {
				vf_filters << 'setpts=2.0*PTS'
				cmd_parts << ['-filter:a', 'atempo=0.5']
			} else if speed_sel.contains('1.5x') {
				vf_filters << 'setpts=0.666*PTS'
				cmd_parts << ['-filter:a', 'atempo=1.5']
			} else if speed_sel.contains('2.0x') {
				vf_filters << 'setpts=0.5*PTS'
				cmd_parts << ['-filter:a', 'atempo=2.0']
			} else if speed_sel.contains('4.0x') {
				vf_filters << 'setpts=0.25*PTS'
				cmd_parts << ['-filter:a', 'atempo=2.0,atempo=2.0']
			}

			fps_sel := win.get('dd_fps')
			if fps_sel.contains('60') { cmd_parts << ['-r', '60'] }
			else if fps_sel.contains('30') { cmd_parts << ['-r', '30'] }
			else if fps_sel.contains('24') { cmd_parts << ['-r', '24'] }

			if vf_filters.len > 0 {
				cmd_parts << ['-vf', '"' + vf_filters.join(',') + '"']
			}
			cmd_parts << ['-c:v', 'libx264', '-crf', '22', '-c:a', 'aac']
		} else if current_tab.contains('Frame') || current_tab.contains('Storyboard') {
			t_stamp := win.get('txt_thumb_time').trim_space()
			sb_mode := win.get('dd_storyboard')
			
			if sb_mode.contains('Single Frame') {
				cmd_parts = [ffmpeg, '-y', '-ss', t_stamp, '-i', '"${in_file}"', '-vframes', '1', '-q:v', '2']
			} else {
				grid_tile := if sb_mode.contains('3x3') { '3x3' } else if sb_mode.contains('5x5') { '5x5' } else { '4x4' }
				cmd_parts = [ffmpeg, '-y', '-i', '"${in_file}"', '-vf', '"fps=1/10,scale=320:-1,tile=${grid_tile}"', '-vframes', '1']
			}
		} else if current_tab.contains('GIF') {
			gif_fps := if win.get('dd_gif_fps').contains('24') { '24' } else if win.get('dd_gif_fps').contains('30') { '30' } else if win.get('dd_gif_fps').contains('20') { '20' } else if win.get('dd_gif_fps').contains('10') { '10' } else { '15' }
			gif_w := if win.get('dd_gif_width').contains('640') { '640' } else if win.get('dd_gif_width').contains('800') { '800' } else if win.get('dd_gif_width').contains('320') { '320' } else { '480' }
			
			cmd_parts << ['-vf', '"fps=${gif_fps},scale=${gif_w}:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"']
		}

		target_out := if out_file != '' { '"${out_file}"' } else { '"output.mp4"' }
		cmd_parts << target_out
		return cmd_parts.join(' ')
	}

	// -------------------------------------------------------------
	// Event Handlers
	// -------------------------------------------------------------

	// Tab switching callback
	win.on_change('tabs_mode', fn (mut w simplegui.SimpleWindow, val string) {
		w.set_control_visible('pane_transcode', val.contains('Transcode'))
		w.set_control_visible('pane_target_size', val.contains('Target Size') || val.contains('Social'))
		w.set_control_visible('pane_audio', val.contains('Audio'))
		w.set_control_visible('pane_trim', val.contains('Trim'))
		w.set_control_visible('pane_filters', val.contains('Aspect') || val.contains('Filters'))
		w.set_control_visible('pane_frames', val.contains('Frame') || val.contains('Storyboard'))
		w.set_control_visible('pane_gif', val.contains('GIF'))
		w.set_control_visible('pane_batch', val.contains('Batch'))
	})

	// Input Browse Button
	win.on_click('btn_browse_in', fn (mut w simplegui.SimpleWindow) {
		path := w.select_file()
		if path != '' {
			w.set('txt_input', path)
			w.append_console('log_console', ' Selected Input: ${path}\n', 1)
			dir := os.dir(path)
			file_stem := os.file_name(path).all_before_last('.')
			default_out := os.join_path(dir, '${file_stem}_converted.mp4')
			if w.get('txt_output') == '' {
				w.set('txt_output', default_out)
			}
		}
	})

	// Output Save As Button
	win.on_click('btn_browse_out', fn (mut w simplegui.SimpleWindow) {
		path := w.save_file_picker()
		if path != '' {
			w.set('txt_output', path)
			w.append_console('log_console', ' Target Output: ${path}\n', 1)
		}
	})

	// Auto Name Button
	win.on_click('btn_auto_out', fn (mut w simplegui.SimpleWindow) {
		in_path := w.get('txt_input').trim_space()
		if in_path == '' {
			w.toast('Please select an input file first.')
			return
		}
		dir := os.dir(in_path)
		stem := os.file_name(in_path).all_before_last('.')
		current_tab := w.get('tabs_mode')
		
		mut ext := 'mp4'
		if current_tab.contains('Audio') {
			fmt := w.get('dd_aformat')
			if fmt.contains('mp3') { ext = 'mp3' }
			else if fmt.contains('flac') { ext = 'flac' }
			else if fmt.contains('wav') { ext = 'wav' }
			else if fmt.contains('ogg') { ext = 'ogg' }
			else if fmt.contains('opus') { ext = 'opus' }
			else { ext = 'm4a' }
		} else if current_tab.contains('GIF') {
			ext = 'gif'
		} else if current_tab.contains('Frame') || current_tab.contains('Storyboard') {
			ext = if w.get('dd_thumb_format').contains('PNG') { 'png' } else { 'jpg' }
		} else if current_tab.contains('Transcode') {
			ext = w.get('dd_container')
			if ext == '' { ext = 'mp4' }
		}

		new_out := os.join_path(dir, '${stem}_output.${ext}')
		w.set('txt_output', new_out)
		w.toast('Auto-configured output filename.')
	})

	// Inspect Media / Probe (Async)
	win.on_click('btn_probe', fn (mut w simplegui.SimpleWindow) {
		in_path := w.get('txt_input').trim_space()
		if in_path == '' || !os.exists(in_path) {
			w.toast('Select a valid input file to inspect.')
			return
		}
		ffprobe := get_ffprobe_bin()
		ffmpeg := get_ffmpeg_bin()
		w.append_console('log_console', ' Probing file: ${in_path}...\n', 1)
		w.set_status('Inspecting media stream metadata...')

		go fn [mut w, in_path, ffprobe, ffmpeg] () {
			res := simplegui.exec_safe(ffprobe, ['-v', 'error', '-show_format', '-show_streams', '-pretty', in_path])
			w.run_on_main_thread(fn [res, in_path, ffmpeg] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('log_console', '=== STREAM & CODEC INFORMATION ===\n' + res.output + '\n', 4)
				} else {
					fres := simplegui.exec_safe(ffmpeg, ['-i', in_path])
					win_main.append_console('log_console', fres.output + '\n', 1)
				}
				win_main.set_status('Media inspection ready.')
				win_main.toast('Metadata inspection complete.')
			})
		}()
	})

	// Batch Directory Picker
	win.on_click('btn_browse_batch_in', fn (mut w simplegui.SimpleWindow) {
		folder := w.select_folder()
		if folder != '' {
			w.set('txt_batch_dir', folder)
			w.append_console('log_console', ' Selected Batch Folder: ${folder}\n', 1)
		}
	})

	// Batch Execution (Async Non-Blocking)
	win.on_click('btn_run_batch', fn (mut w simplegui.SimpleWindow) {
		dir := w.get('txt_batch_dir').trim_space()
		if dir == '' || !os.is_dir(dir) {
			w.alert('Folder Required', 'Please select a valid folder for batch processing.')
			return
		}
		ffmpeg := get_ffmpeg_bin()
		files := os.ls(dir) or { []string{} }
		mode := w.get('dd_batch_format')

		w.append_console('log_console', ' Starting batch processing on folder: ${dir} (Async Background Queue)...\n', 1)
		w.set_status('Batch processing running in background...')

		go fn [mut w, dir, files, mode, ffmpeg] () {
			mut processed := 0
			for f in files {
				ext := os.file_ext(f).to_lower()
				if ext in ['.mp4', '.mov', '.mkv', '.avi', '.webm', '.flv', '.wmv', '.m4v'] {
					full_in := os.join_path(dir, f)
					stem := f.all_before_last('.')
					
					mut raw_args := ['-y', '-i', full_in]
					mut full_out := ''
					if mode.contains('MP3') {
						full_out = os.join_path(dir, '${stem}_batch.mp3')
						raw_args << ['-vn', '-c:a', 'libmp3lame', '-b:a', '256k', full_out]
					} else if mode.contains('WAV') {
						full_out = os.join_path(dir, '${stem}_batch.wav')
						raw_args << ['-vn', '-c:a', 'pcm_s16le', full_out]
					} else if mode.contains('WebM') {
						full_out = os.join_path(dir, '${stem}_batch.webm')
						raw_args << ['-c:v', 'libvpx-vp9', '-crf', '30', '-b:v', '0', '-c:a', 'libopus', full_out]
					} else {
						full_out = os.join_path(dir, '${stem}_batch.mp4')
						raw_args << ['-c:v', 'libx264', '-crf', '23', '-preset', 'fast', '-c:a', 'aac', '-b:a', '192k', full_out]
					}

					w.run_on_main_thread(fn [f] (mut win_main simplegui.SimpleWindow) {
						win_main.append_console('log_console', ' Processing: ${f}...\n', 1)
					})

					res := simplegui.exec_safe(ffmpeg, raw_args)
					if res.exit_code == 0 {
						processed++
						w.run_on_main_thread(fn [f] (mut win_main simplegui.SimpleWindow) {
							win_main.append_console('log_console', ' Finished: ${f}\n', 4)
						})
					} else {
						w.run_on_main_thread(fn [f] (mut win_main simplegui.SimpleWindow) {
							win_main.append_console('log_console', ' Failed: ${f}\n', 3)
						})
					}
				}
			}

			w.run_on_main_thread(fn [processed] (mut win_main simplegui.SimpleWindow) {
				win_main.append_console('log_console', ' Batch Complete! Processed ${processed} files.\n', 4)
				win_main.set_status('Batch processing finished.')
				win_main.toast('Batch processing complete: ${processed} files.')
			})
		}()
	})

	// Refresh Command
	win.on_click('btn_build_cmd', fn [build_command] (mut w simplegui.SimpleWindow) {
		cmd := build_command(w)
		w.set('txt_command', cmd)
		w.toast('Command refreshed.')
	})

	// Copy Command
	win.on_click('btn_copy_cmd', fn [build_command] (mut w simplegui.SimpleWindow) {
		mut cmd := w.get('txt_command').trim_space()
		if cmd == '' || cmd.contains('<input_file>') {
			cmd = build_command(w)
			w.set('txt_command', cmd)
		}
		w.copy_to_clipboard(cmd)
		w.toast('Command copied to clipboard!')
	})

	// Clear Log
	win.on_click('btn_clear_log', fn (mut w simplegui.SimpleWindow) {
		w.clear_console('log_console')
		w.set_status('Log cleared.')
	})

	// Reveal in Finder
	win.on_click('btn_reveal', fn (mut w simplegui.SimpleWindow) {
		out_path := w.get('txt_output').trim_space()
		if out_path == '' || !os.exists(out_path) {
			w.toast('Output file does not exist yet.')
			return
		}
		os.execute('open -R "${out_path}"')
		w.toast('Revealed in Finder.')
	})

	// Run Processing Task (Async Non-Blocking Thread)
	win.on_click('btn_run', fn [build_command] (mut w simplegui.SimpleWindow) {
		in_path := w.get('txt_input').trim_space()
		out_path := w.get('txt_output').trim_space()

		if in_path == '' || !os.exists(in_path) {
			w.alert('Input Error', 'Please select an existing input file first.')
			return
		}

		if out_path == '' {
			w.alert('Output Error', 'Please specify a destination output path.')
			return
		}

		mut cmd := w.get('txt_command').trim_space()
		if cmd == '' || cmd.contains('<input_file>') {
			cmd = build_command(w)
			w.set('txt_command', cmd)
		}

		w.append_console('log_console', '----------------------------------------\n', 1)
		w.append_console('log_console', ' Executing in Background: ${cmd}\n', 1)
		w.set_status('FFmpeg processing running asynchronously (UI responsive)...')
		w.toast('Encoding started in background!')

		// Spawn background thread to prevent beach ball
		go fn [mut w, cmd, out_path] () {
			res := os.execute(cmd)

			w.run_on_main_thread(fn [res, out_path] (mut win_main simplegui.SimpleWindow) {
				if res.exit_code == 0 {
					win_main.append_console('log_console', ' Task Completed Successfully!\n', 4)
					if os.exists(out_path) {
						size_bytes := os.file_size(out_path)
						size_mb := f64(size_bytes) / (1024.0 * 1024.0)
						win_main.append_console('log_console', ' Output Created: ${out_path} (${size_mb:.2f} MB)\n', 4)
					}
					win_main.set_status('FFmpeg task completed with success.')
					win_main.toast('FFmpeg processing finished successfully!')
				} else {
					win_main.append_console('log_console', ' Error during execution (Exit code ${res.exit_code}):\n' + res.output + '\n', 3)
					win_main.set_status('Error executing FFmpeg.')
					win_main.alert('FFmpeg Error', 'Failed to process media file. Check console logs for details.')
				}
			})
		}()
	})

	println('FFmpeg Studio Pro configured. Starting event loop...')
	win.run()
}
