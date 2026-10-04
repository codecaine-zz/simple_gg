module envutils

import os
import time

fn test_dotenv_roundtrip_with_special_chars() {
	vals := {
		'A': 'has "quotes" and \\ backslash'
		'B': 'line1\nline2\ttab'
		'C': "it's # not a comment"
		'D': 'price=\$5'
		'E': 'plain'
	}
	path := os.join_path(os.temp_dir(), 'envutils_rt_${os.getpid()}.env')
	defer {
		os.rm(path) or {}
	}
	save_dotenv(path, vals)!
	got := parse_dotenv_content(os.read_file(path)!)
	for k, v in vals {
		assert got[k] == v, '${k}: ${got[k]} != ${v}'
	}
}

fn test_dotenv_syntax_extensions() {
	src := 'export TOKEN=abc\nMULTI="first\nsecond"\nURL=http://x/y#frag\nC=v # comment\nSQ=\'raw \\n kept\'\n'
	m := parse_dotenv_content(src)
	assert m['TOKEN'] == 'abc'
	assert m['MULTI'] == 'first\nsecond'
	assert m['URL'] == 'http://x/y#frag'
	assert m['C'] == 'v'
	assert m['SQ'] == 'raw \\n kept'
}

fn test_expand_defaults() {
	vars := {
		'HOST':  'db'
		'EMPTY': ''
	}
	assert expand_with('\${HOST}:\${PORT:-5432}', vars) == 'db:5432'
	assert expand_with('\${EMPTY:-x}|\${EMPTY-y}|\${NOPE-z}', vars) == 'x||z'
	assert expand_with('cost \$\$5 on \$HOST', vars) == 'cost \$5 on db'
	os.unsetenv('VU_UNSET_X')
	assert expand_env('\${VU_UNSET_X:-fallback}') == 'fallback'
}

fn test_dotenv_expand() {
	m := parse_dotenv_expand('BASE=/srv\nDATA=\${BASE}/data\nLOG=\${DATA}/log')
	assert m['LOG'] == '/srv/data/log'
}

fn test_typed_getters() {
	with_env({
		'VU_DUR':  '250ms'
		'VU_MODE': 'PROD'
	}, fn () {
		assert get_duration('VU_DUR', 0) == 250 * time.millisecond
		assert get_enum('VU_MODE', ['dev', 'prod'], 'dev') == 'prod'
	})
	assert os.getenv_opt('VU_DUR') == none
	assert get_duration('VU_DUR', time.second) == time.second
	if _ := require_all(['VU_DEFINITELY_MISSING']) {
		assert false
	}
}

fn test_no_override() {
	path := os.join_path(os.temp_dir(), 'envutils_no_${os.getpid()}.env')
	os.write_file(path, 'VU_KEEP=new\nVU_FRESH=yes')!
	defer {
		os.rm(path) or {}
		os.unsetenv('VU_KEEP')
		os.unsetenv('VU_FRESH')
	}
	os.setenv('VU_KEEP', 'old', true)
	load_dotenv_no_override(path)!
	assert os.getenv('VU_KEEP') == 'old'
	assert os.getenv('VU_FRESH') == 'yes'
}
