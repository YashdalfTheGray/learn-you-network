# frozen_string_literal: true

unless ENV['EMITTER_URL'] && ENV['AUTH_TOKEN']
  require 'dotenv'
  Dotenv.load
  Dotenv.require_keys('EMITTER_URL', 'AUTH_TOKEN')
end

require 'uri'
require 'net/http'

require 'sinatra'

port = ENV['PORT'] || 8080
proxy_port = ENV['PROXY_PORT'] || port

uri = URI("#{ENV['EMITTER_URL']}/register")
http = Net::HTTP.new(uri.host, uri.port)

init_request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
init_request.body = { port: proxy_port, auth_token: ENV['AUTH_TOKEN'] }.to_json
res = http.request(init_request)

raise "Failed to register with #{ENV['EMITTER_URL']}" unless res.is_a? Net::HTTPSuccess

puts "Registered successfully with #{ENV['EMITTER_URL']}, response was #{res}"

configure do
  enable :logging
  set port: port
  set bind: '0.0.0.0'
end

get '/' do
  [
    200,
    { status: 'ok', env_found: !ENV['EMITTER_URL'].nil? && !ENV['AUTH_TOKEN'].nil? }.to_json
  ]
end

post '/message' do
  request.body.rewind
  data = JSON.parse(request.body.read, symbolize_names: true)
  puts "Received message \"#{data[:message]}\" from #{data[:sender]}"

  200
end
