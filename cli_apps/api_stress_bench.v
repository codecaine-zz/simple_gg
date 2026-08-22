// API Stress Bench & HTTP Performance Analyzer
// Production Console Application built with SimpleCLI
//
// Usage:
//   v run cli_apps/api_stress_bench.v --url https://httpbin.org/get --requests 20 --concurrency 4
//   v run cli_apps/api_stress_bench.v --url https://httpbin.org/post --method POST --body '{"test":1}' --requests 50
//   v run cli_apps/api_stress_bench.v --url https://httpbin.org/get --export bench.json

module main

import time
import net.http
import simplecli

struct RequestResult {
	duration_ms f64
	status_code int
	is_success  bool
	error_msg   string
}

fn main() {
	mut app := simplecli.new_app('API-Stress-Bench', '1.0.0')
	app.set_description('High-Performance HTTP API Benchmark & Latency Stress Tester')

	app.add_flag_string('url', 'u', 'https://httpbin.org/get', 'Target URL to benchmark')
	app.add_flag_string('method', 'm', 'GET', 'HTTP method (GET, POST, PUT, DELETE, HEAD)')
	app.add_flag_string('body', 'b', '', 'Request payload string for POST/PUT')
	app.add_flag_int('requests', 'n', 20, 'Total number of requests to execute')
	app.add_flag_int('concurrency', 'c', 4, 'Number of concurrent worker threads')
	app.add_flag_string('export', 'e', '', 'Export benchmark results to JSON file')

	app.parse_cli() or { return }

	target_url := app.get_flag_string('url')
	method := app.get_flag_string('method').to_upper()
	body := app.get_flag_string('body')
	total_reqs := app.get_flag_int('requests')
	concurrency := app.get_flag_int('concurrency')
	export_path := app.get_flag_string('export')

	app.banner('API Stress Bench & Latency Analyzer', 'v1.0.0 - High-Throughput HTTP Engine')

	if !app.validate_url(target_url) {
		app.error('Invalid URL format: "${target_url}". Must start with http:// or https://')
		return
	}

	app.print_kv({
		'Target URL':   target_url,
		'HTTP Method':  method,
		'Total Count':  '${total_reqs} requests',
		'Concurrency':  '${concurrency} worker threads',
	})

	app.step(1, 'Executing high-concurrency benchmark run')

	// Distribute work to concurrent workers
	reqs_per_worker := total_reqs / concurrency
	remainder := total_reqs % concurrency

	start_bench := time.now()
	mut threads := []thread []RequestResult{}

	for w := 0; w < concurrency; w++ {
		count := reqs_per_worker + if w == 0 { remainder } else { 0 }
		threads << spawn fn (url string, meth string, payload string, n int) []RequestResult {
			mut res_list := []RequestResult{cap: n}
			for _ in 0 .. n {
				t0 := time.now()
				req_method := match meth {
					'POST' { http.Method.post }
					'PUT' { http.Method.put }
					'DELETE' { http.Method.delete }
					'HEAD' { http.Method.head }
					else { http.Method.get }
				}
				mut req := http.new_request(req_method, url, payload)
				resp := req.do() or {
					elapsed := f64(time.since(t0).microseconds()) / 1000.0
					res_list << RequestResult{
						duration_ms: elapsed
						status_code: 0
						is_success: false
						error_msg: err.str()
					}
					continue
				}
				elapsed := f64(time.since(t0).microseconds()) / 1000.0
				res_list << RequestResult{
					duration_ms: elapsed
					status_code: resp.status_code
					is_success: resp.status_code >= 200 && resp.status_code < 400
					error_msg: ''
				}
			}
			return res_list
		}(target_url, method, body, count)
	}

	// Join results
	mut all_results := []RequestResult{}
	for t in threads {
		worker_res := t.wait()
		all_results << worker_res
	}

	total_duration_sec := f64(time.since(start_bench).milliseconds()) / 1000.0
	throughput_rps := if total_duration_sec > 0 { f64(all_results.len) / total_duration_sec } else { 0.0 }

	app.step(2, 'Computing Statistical Metrics & Latency Distribution')

	mut latencies := []f64{}
	mut status_counts := map[int]int{}
	mut successes := 0
	mut failures := 0

	for r in all_results {
		latencies << r.duration_ms
		if r.status_code in status_counts {
			status_counts[r.status_code]++
		} else {
			status_counts[r.status_code] = 1
		}
		if r.is_success {
			successes++
		} else {
			failures++
		}
	}

	// Mathematical Stats
	mean_lat := app.stats_mean(latencies)
	median_lat := app.stats_median(latencies)
	std_dev_lat := app.stats_std_dev(latencies)
	rms_lat := app.stats_rms(latencies)
	min_lat := app.stats_min(latencies)
	max_lat := app.stats_max(latencies)

	app.print_kv({
		'Total Duration': '${total_duration_sec:.2f} seconds',
		'Throughput':     '${throughput_rps:.1f} req/sec',
		'Success / Fail': '${app.green(successes.str())} success / ${if failures > 0 { app.red(failures.str()) } else { '0' }} errors',
		'Fastest (Min)':  '${min_lat:.2f} ms',
		'Slowest (Max)':  '${max_lat:.2f} ms',
		'Average (Mean)': '${mean_lat:.2f} ms',
		'Median (p50)':   '${median_lat:.2f} ms',
		'Std Deviation':  '±${std_dev_lat:.2f} ms',
		'Root Mean Sq':   '${rms_lat:.2f} ms',
	})

	app.step(3, 'HTTP Status Code Distribution Breakdown')
	mut status_rows := [][]string{}
	for code, count in status_counts {
		code_label := if code == 0 { 'Network Error / Timeout' } else { '${code}' }
		pct := (f64(count) / f64(all_results.len)) * 100.0
		cnt_str := '${count}'
		pct_str := '${pct:.1f}%'
		status_rows << [code_label, cnt_str, pct_str]
	}
	app.table(['HTTP Status Code', 'Response Count', 'Percentage'], status_rows)

	// JSON Export if requested
	if export_path.len > 0 {
		app.step(4, 'Exporting Benchmark Metrics to JSON')
		report := '{\n  "target_url": "${target_url}",\n  "method": "${method}",\n  "total_requests": ${all_results.len},\n  "concurrency": ${concurrency},\n  "duration_sec": ${total_duration_sec},\n  "throughput_rps": ${throughput_rps},\n  "latency_mean_ms": ${mean_lat},\n  "latency_median_ms": ${median_lat},\n  "latency_min_ms": ${min_lat},\n  "latency_max_ms": ${max_lat},\n  "latency_std_dev_ms": ${std_dev_lat}\n}\n'
		app.write_file(export_path, report)
		app.success('Report saved to: ${export_path}')
	}

	app.divider('─', 64)
	app.success('API benchmark completed in ${app.elapsed_ms()} ms.')
}
