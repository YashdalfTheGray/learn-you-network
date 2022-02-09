# frozen_string_literal: true

unless ENV['SENDER_ID']
  require 'dotenv'
  Dotenv.load
  Dotenv.require_keys('SENDER_ID')
end

require 'sinatra'

require 'uri'
require 'net/http'

configure do
  enable :logging
  set port: ENV['PORT'] || 9001
  set bind: '0.0.0.0'
end

known_listeners = []

post '/register' do
  request.body.rewind
  data = JSON.parse(request.body.read, symbolize_names: true)
  puts "Received registration request with token #{data[:auth_token]}"
  known_listeners << "#{request.ip}:#{data[:port]}"

  known_listeners = known_listeners.uniq

  200
end

post '/emit' do
  request.body.rewind
  data = JSON.parse(request.body.read, symbolize_names: true)

  unknown_listeners = []

  known_listeners.each do |listener|
    uri = URI("http://#{listener}/message")
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
    request.body = { message: data[:message], sender: ENV['SENDER_ID'] }.to_json
    res = http.request(request)

    unknown_listeners << listener unless res.is_a? Net::HTTPSuccess
  end

  puts "Found #{unknown_listeners.length} unknown listeners"
  known_listeners -= unknown_listeners

  200
end
