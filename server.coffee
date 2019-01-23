#!/usr/bin/env coffee

_ = require 'lodash'
fs = require 'fs'
path = require 'path'
child_process = require 'child_process'
express = require 'express'
morgan = require 'morgan'
commander = require 'commander'
pkg = require './package.json'

commander
	.description pkg.description
	.option '-p, --port <number>', "HTTP server port", 18000
	.option '-t, --template <filename>', "preseed template", path.join(__dirname, 'template-example.cfg')
	.option '-c, --config <filename.json>', "configuration file", path.join(__dirname, 'config-example.json')
	.option '-H, --hostnames <filename.json>', "list of hostnames"
	.option '-n, --no-apt-proxy-detect', "do NOT automatically detect apt-proxy on local network"
	.version pkg.version
	.parse process.argv

config = {}
try
	fs.accessSync commander.config, fs.constants.R_OK
	config = JSON.parse fs.readFileSync commander.config
	if typeof config.PACKAGES_ADDITIONAL is 'object'
		config.PACKAGES_ADDITIONAL = config.PACKAGES_ADDITIONAL.join '\\\n\t'
catch error
	console.error error.message
	console.error "Unable to load configuration:", commander.config
	process.exit 2

try
	fs.accessSync commander.template, fs.constants.R_OK
	preseedTemplateSource = fs.readFileSync commander.template
	preseedTemplate = _.template preseedTemplateSource.toString()
catch error
	console.error error.message
	console.error "Unable to load preseed template:", commander.template
	process.exit 2

# set hostname and generate a new set of password hashes
generateConfig = (hostname) ->
	preseedTemplate _.assign config,
		HOSTNAME: hostname
		CRYPT_PASSWD_ROOT: child_process.execSync("mkpasswd -m SHA-512 #{config.PASSWD_ROOT}").toString().trim()
		CRYPT_PASSWD_USER: child_process.execSync("mkpasswd -m SHA-512 #{config.PASSWD_USER}").toString().trim()

# test and crash now instead of waiting for the first HTTP request
try
	generateConfig "test"
catch error
	console.error "Error generating preseed output:", error.message
	process.exit 3

app = module.exports = express()
app.use morgan 'dev' # HTTP request logger

app.get '/', (req, res) ->
	getHostnameList
		.then (hostnameList) ->
			throw new Error if hostnameList.length is 0
			res.type('txt').send generateConfig _.sample hostnameList
		.catch ->
			res.status(404).type('txt').send "Required: /hostname"

app.get '/favicon.ico', (req, res) -> res.sendStatus 404

app.get '/:hostname', (req, res) ->
	res.type('txt').send generateConfig req.params.hostname

server = app.listen parseInt(commander.port) or 0, ->
	serverInfo = server.address()
	if serverInfo.family is 'IPv6' then serverInfo.address = "[#{serverInfo.address}]"
	console.log "[#{process.pid}] http://#{serverInfo.address}:#{serverInfo.port}/"

getHostnameList = new Promise (resolve, reject) ->
	if not commander.hostnames or not commander.hostnames.length
		reject()
		return
	fs.accessSync commander.hostnames, fs.constants.R_OK
	resolve JSON.parse fs.readFileSync commander.hostnames

getHostnameList.catch (error) ->
	return if not error or not error.message
	console.error error.message
	console.error "Unable to load hostnames:", commander.hostnames

if commander.aptProxyDetect
	console.log "Looking for apt-proxy on the local network..."
	require './aptProxyDetect'
		.then (urlAptProxy) ->
			console.log "apt-proxy found at #{urlAptProxy}"
			config.URL_PROXY = urlAptProxy
		.catch (error) ->
			if error and error.message
				console.error "apt-proxy lookup failed:", error.message
			else
				console.error error
