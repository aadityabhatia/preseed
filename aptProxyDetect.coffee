child_process = require 'child_process'
net = require 'net'

module.exports =
	new Promise (resolve, reject) ->
		process = child_process.spawn 'avahi-browse', ['-kprtf', '_apt_proxy._tcp']
		process.on 'error', reject
		process.on 'exit', (code, signal) ->
			if code or signal
				reject "Child process exited with non-zero status. code: #{code}, signal: #{signal}"
				return
			stdoutBuffer = @stdout.read()
			if not stdoutBuffer then return reject "apt-proxy not found"
			lines = stdoutBuffer.toString().split('\n').filter (str) => str.startsWith '='
			for line in lines
				tokens = line.split ';'
				addr = tokens[7]
				port = tokens[8]
				if net.isIPv4 addr
					return resolve "http://#{addr}:#{port}"
				# ignore IPv6 link-local addresses
				if net.isIPv6 addr and not addr.startsWith 'fe'
					return resolve "http://[#{addr}]:#{port}"
			reject "apt-proxy not found"
