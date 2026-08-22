// Multi-Repository Git Pilot & Workspace Orchestrator
// Production Console Application built with SimpleCLI
//
// Usage:
//   v run cli_apps/multirepo_git_pilot.v --path .
//   v run cli_apps/multirepo_git_pilot.v --path ~/projects --fetch
//   v run cli_apps/multirepo_git_pilot.v --path ~/projects --dirty-only

module main

import os
import simplecli

struct RepoStatus {
	name        string
	path        string
	branch      string
	is_dirty    bool
	untracked   int
	modified    int
	ahead       int
	behind      int
}

fn main() {
	mut app := simplecli.new_app('Git-Pilot', '1.0.0')
	app.set_description('Multi-Repository Git Workspace Orchestrator & Synchronizer')

	app.add_flag_string('path', 'p', '.', 'Root directory to scan for Git repositories')
	app.add_flag_bool('fetch', 'f', false, 'Run git fetch across all repositories in parallel')
	app.add_flag_bool('dirty-only', 'd', false, 'Only display repositories with uncommitted changes')
	app.add_flag_bool('interactive', 'i', false, 'Launch interactive batch sync wizard')

	app.parse_cli() or { return }

	root_dir := app.get_flag_string('path')
	do_fetch := app.get_flag_bool('fetch')
	dirty_only := app.get_flag_bool('dirty-only')
	is_interactive := app.get_flag_bool('interactive')

	app.banner('Git Workspace Pilot', 'v1.0.0 - Multi-Repository Orchestrator')

	if !app.command_exists('git') {
		app.error('Git executable is required but was not found in system PATH.')
		return
	}

	app.step(1, 'Scanning for Git repositories in: ${root_dir}')
	repos := find_git_repos(mut app, root_dir)
	app.info('Found ${repos.len} Git repository/repositories.')

	if repos.len == 0 {
		app.warn('No Git repositories found in target path.')
		return
	}

	if do_fetch {
		app.step(2, 'Running parallel git fetch across ${repos.len} repos')
		mut fetch_cmds := []string{}
		for r in repos {
			fetch_cmds << 'cd "${r}" && git fetch --all --prune'
		}
		app.parallel_exec(fetch_cmds)
		app.success('Fetch completed.')
	}

	app.step(3, 'Analyzing branch states and uncommitted changes')
	mut repo_statuses := []RepoStatus{}

	for r in repos {
		branch, _ := app.exec_in_dir(r, 'git rev-parse --abbrev-ref HEAD')
		status_out, _ := app.exec_in_dir(r, 'git status --porcelain')
		
		lines := status_out.split_into_lines().filter(it.len > 0)
		mut untracked_cnt := 0
		mut mod_cnt := 0
		for l in lines {
			if l.starts_with('??') {
				untracked_cnt++
			} else {
				mod_cnt++
			}
		}

		repo_statuses << RepoStatus{
			name: os.file_name(r)
			path: r
			branch: branch
			is_dirty: lines.len > 0
			untracked: untracked_cnt
			modified: mod_cnt
			ahead: 0
			behind: 0
		}
	}

	mut table_rows := [][]string{}
	mut dirty_count := 0

	for s in repo_statuses {
		if dirty_only && !s.is_dirty {
			continue
		}
		if s.is_dirty {
			dirty_count++
		}

		status_str := if s.is_dirty {
			app.yellow('● DIRTY (${s.modified} mod, ${s.untracked} untracked)')
		} else {
			app.green('✓ CLEAN')
		}

		table_rows << [s.name, s.branch, status_str, s.path]
	}

	app.table(['Repository', 'Active Branch', 'Working Tree State', 'Directory Path'], table_rows)

	app.print_kv({
		'Total Repositories': '${repos.len}',
		'Clean Repositories': '${repos.len - dirty_count}',
		'Dirty Repositories': '${dirty_count}',
	})

	if is_interactive && dirty_count > 0 {
		app.step(4, 'Interactive Batch Stash / Commit Wizard')
		action := app.select('Choose batch operation for dirty repositories:', [
			'Review modified files',
			'Stash all changes',
			'Cancel',
		])

		if action == 'Review modified files' {
			for s in repo_statuses {
				if s.is_dirty {
					out, _ := app.exec_in_dir(s.path, 'git status -s')
					app.panel('Repo: ${s.name}', out)
				}
			}
		} else if action == 'Stash all changes' {
			for s in repo_statuses {
				if s.is_dirty {
					app.exec_in_dir(s.path, 'git stash push -m "Auto-stashed by Git-Pilot"')
					app.info('Stashed changes in: ${s.name}')
				}
			}
			app.success('Batch stash operation completed.')
		}
	}

	app.divider('─', 64)
	app.info('Pilot analysis completed in ${app.elapsed_ms()} ms.')
}

fn find_git_repos(mut app simplecli.SimpleCli, root string) []string {
	resolved := simplecli.resolve_user_path(root)
	mut results := []string{}

	if app.file_exists(os.join_path(resolved, '.git')) {
		results << resolved
		return results
	}

	entries := app.read_dir(resolved)
	for e in entries {
		sub := os.join_path(resolved, e)
		if app.is_dir(sub) && !e.starts_with('.') && e != 'node_modules' && e != 'vendor' {
			if app.file_exists(os.join_path(sub, '.git')) {
				results << sub
			}
		}
	}
	return results
}
