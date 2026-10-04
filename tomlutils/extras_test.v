module tomlutils

struct ServerCfg {
	host  string
	port  int
	debug bool
}

const sample = '
title = "demo"

[server]
host = "0.0.0.0"
port = 8080
ratios = [0.5, 1.5]
flags = [true, false, true]

[server.limits]
rps = 100
burst = 20

[labels]
env = "prod"
team = "core"
'

fn test_get_and_require() {
	d := parse(sample) or { panic(err) }
	assert (d.get('server.port') or { panic('missing') }).int() == 8080
	assert d.get('nope') == none
	assert d.require_string('title') or { '' } == 'demo'
	assert d.require_int('server.limits.rps') or { 0 } == 100
	d.require_string('server.missing') or {
		assert err.msg().contains('server.missing')
		return
	}
	assert false
}

fn test_arrays_maps_keys() {
	d := parse(sample) or { panic(err) }
	assert d.get_f64s('server.ratios') == [0.5, 1.5]
	assert d.get_bools('server.flags') == [true, false, true]
	assert d.get_array('absent').len == 0
	assert d.get_string_map('labels') == {
		'env':  'prod'
		'team': 'core'
	}
	assert d.keys('') == ['labels', 'server', 'title']
	assert d.keys('server.limits') == ['burst', 'rps']
	assert d.keys('missing') == []
}

fn test_to_json() {
	d := parse('a = 1\n[b]\nc = "x"') or { panic(err) }
	j := d.to_json()
	assert j.contains('"a": 1') || j.contains('"a":1')
	assert j.contains('"c"')
}

fn test_decode_encode_struct() {
	cfg := decode[ServerCfg]('host = "localhost"\nport = 9000\ndebug = true') or { panic(err) }
	assert cfg.host == 'localhost' && cfg.port == 9000 && cfg.debug
	text := encode(cfg)
	back := decode[ServerCfg](text) or { panic(err) }
	assert back == cfg
}
