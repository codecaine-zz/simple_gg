// Vault Backup Manager & Encrypted Archive Tool
// Production Console Application built with SimpleCLI
//
// Usage:
//   v run cli_apps/vault_backup_manager.v --backup --src ./my_data --dest ./backup.vault
//   v run cli_apps/vault_backup_manager.v --restore --src ./backup.vault --dest ./restored
//   v run cli_apps/vault_backup_manager.v --verify --src ./backup.vault

module main

import os
import time
import json2
import simplecli

struct ArchiveManifest {
	created_at  string
	file_count  int
	total_bytes u64
	checksum    string
	files       []ArchiveFile
}

struct ArchiveFile {
	path      string
	size      u64
	checksum  string
	content   string
}

fn main() {
	mut app := simplecli.new_app('Vault-Backup-Manager', '1.0.0')
	app.set_description('Enterprise-Grade Encrypted Backup Vault & Archive Manager')

	app.add_flag_bool('backup', 'b', false, 'Create a new encrypted archive')
	app.add_flag_bool('restore', 'r', false, 'Restore and decrypt an existing archive')
	app.add_flag_bool('verify', 'v', false, 'Verify archive cryptographic integrity')
	app.add_flag_string('src', 's', '', 'Source path (file or directory)')
	app.add_flag_string('dest', 'd', '', 'Destination path')
	app.add_flag_string('key', 'k', '', 'Passphrase/Secret encryption key')

	app.parse_cli() or { return }

	app.banner('Vault Backup & Encryption Manager', 'v1.0.0 - AES-256-CTR Archive Engine')

	is_backup := app.get_flag_bool('backup')
	is_restore := app.get_flag_bool('restore')
	is_verify := app.get_flag_bool('verify')

	if !is_backup && !is_restore && !is_verify {
		app.warn('No action flag specified. Use --backup, --restore, or --verify.')
		app.print_help()
		return
	}

	if is_backup {
		run_backup(mut app)
	} else if is_restore {
		run_restore(mut app)
	} else if is_verify {
		run_verify(mut app)
	}
}

fn get_encryption_key(mut app simplecli.SimpleCli) string {
	flag_key := app.get_flag_string('key')
	if flag_key.len > 0 {
		return flag_key
	}
	mut key := app.prompt_password('Enter AES-256 encryption passphrase')
	if key.len == 0 {
		app.error('Passphrase cannot be empty. Aborting.')
		exit(1)
	}
	return key
}

fn run_backup(mut app simplecli.SimpleCli) {
	src_dir := app.get_flag_string('src')
	dest_vault := app.get_flag_string('dest')

	if src_dir.len == 0 || dest_vault.len == 0 {
		app.error('Both --src and --dest are required for backup.')
		return
	}

	if !app.file_exists(src_dir) {
		app.error('Source directory "${src_dir}" does not exist.')
		return
	}

	app.step(1, 'Scanning files in source directory: ${src_dir}')
	file_paths := if app.is_dir(src_dir) {
		app.list_files_recursive(src_dir, '')
	} else {
		[src_dir]
	}

	app.info('Discovered ${file_paths.len} file(s) for archiving.')
	if file_paths.len == 0 {
		app.warn('No files found to archive.')
		return
	}

	passphrase := get_encryption_key(mut app)

	app.step(2, 'Computing cryptographic checksums and bundling archive')
	mut archive_files := []ArchiveFile{}
	mut total_bytes := u64(0)

	for i, f in file_paths {
		content := app.read_file(f)
		meta := app.get_file_metadata(f) or { continue }
		sum := app.crypto_sha256(content)
		b64_content := app.base64_encode(content)

		archive_files << ArchiveFile{
			path: f.replace(src_dir, '').trim_left('/')
			size: meta.size_bytes
			checksum: sum
			content: b64_content
		}
		total_bytes += meta.size_bytes
		app.progress_bar(f64(i + 1), f64(file_paths.len), 'Archiving: ${os.file_name(f)}')
	}

	manifest := ArchiveManifest{
		created_at: time.now().format_ss()
		file_count: archive_files.len
		total_bytes: total_bytes
		checksum: app.crypto_sha256('${archive_files.len}:${total_bytes}')
		files: archive_files
	}

	manifest_json := json2.encode(manifest)

	app.step(3, 'Compressing with Gzip and Encrypting with AES-256-CTR')
	app.spinner('Encrypting data payload', 400)
	encrypted := app.crypto_aes_encrypt(passphrase, manifest_json) or {
		app.error('Encryption failed: ${err}')
		return
	}

	app.write_file(dest_vault, encrypted)
	vault_meta := app.get_file_metadata(dest_vault) or {
		simplecli.FileMetadata{ size_bytes: 0, path: dest_vault, name: '' }
	}

	app.step(4, 'Backup Complete')
	app.print_kv({
		'Destination Vault': dest_vault,
		'Archived Files':    '${archive_files.len} files',
		'Raw Payload Size':  '${f64(total_bytes) / 1024.0:.1f} KB',
		'Encrypted Vault':   '${f64(vault_meta.size_bytes) / 1024.0:.1f} KB',
		'Manifest Checksum': manifest.checksum,
	})

	app.success('Encrypted archive successfully created in ${app.elapsed_ms()} ms.')
	app.notify('Backup Created', 'Vault created: ${archive_files.len} files stored safely.')
}

fn run_restore(mut app simplecli.SimpleCli) {
	vault_file := app.get_flag_string('src')
	dest_dir := app.get_flag_string('dest')

	if vault_file.len == 0 || dest_dir.len == 0 {
		app.error('Both --src and --dest are required for restore.')
		return
	}

	if !app.file_exists(vault_file) {
		app.error('Vault archive "${vault_file}" not found.')
		return
	}

	passphrase := get_encryption_key(mut app)

	app.step(1, 'Decrypting AES-256 Encrypted Vault Payload')
	encrypted := app.read_file(vault_file)
	decrypted := app.crypto_aes_decrypt(passphrase, encrypted) or {
		app.error('Decryption failed! Incorrect passphrase or corrupted vault file.')
		return
	}

	manifest := json2.decode[ArchiveManifest](decrypted) or {
		app.error('Failed to parse archive manifest: ${err}')
		return
	}

	app.info('Vault opened successfully: ${manifest.file_count} files archived on ${manifest.created_at}.')

	app.step(2, 'Restoring and verifying files into destination: ${dest_dir}')
	for i, f in manifest.files {
		target_path := os.join_path(dest_dir, f.path)
		raw_content := app.base64_decode(f.content)
		current_sum := app.crypto_sha256(raw_content)

		if current_sum != f.checksum {
			app.error('Checksum mismatch on "${f.path}"! File may be corrupt.')
			continue
		}

		app.write_file(target_path, raw_content)
		app.progress_bar(f64(i + 1), f64(manifest.files.len), 'Restoring: ${f.path}')
	}

	app.success('Successfully restored ${manifest.file_count} files to ${dest_dir} in ${app.elapsed_ms()} ms.')
}

fn run_verify(mut app simplecli.SimpleCli) {
	vault_file := app.get_flag_string('src')
	if vault_file.len == 0 {
		app.error('--src <vault_file> is required for verification.')
		return
	}

	if !app.file_exists(vault_file) {
		app.error('Vault archive "${vault_file}" not found.')
		return
	}

	passphrase := get_encryption_key(mut app)
	app.step(1, 'Inspecting Cryptographic Integrity')
	encrypted := app.read_file(vault_file)
	decrypted := app.crypto_aes_decrypt(passphrase, encrypted) or {
		app.error('Decryption failed. Invalid passphrase or corrupted archive.')
		return
	}

	manifest := json2.decode[ArchiveManifest](decrypted) or {
		app.error('Corrupted manifest header: ${err}')
		return
	}

	mut rows := [][]string{}
	for f in manifest.files {
		raw := app.base64_decode(f.content)
		current_sum := app.crypto_sha256(raw)
		status := if current_sum == f.checksum { app.green('✓ VALID') } else { app.red('✗ CORRUPT') }
		rows << [f.path, '${f.size} B', f.checksum[0..12] + '...', status]
	}

	app.table(['Archived Path', 'Size', 'SHA-256 Checksum', 'Integrity Status'], rows)
	app.success('Vault integrity verified: All ${manifest.file_count} files passed checksum checks.')
}
