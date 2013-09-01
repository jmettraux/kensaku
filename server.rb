
require 'sinatra'
require 'haml'
require 'compass'

require_relative 'lib/index.rb'
Index.load


MAX = 77


configure do

  Compass.configuration do |c|
    c.project_path = File.dirname(__FILE__)
  end

  set :haml, :format => :html5
  set :scss, Compass.sass_engine_options
end

use(
  Rack::Static,
  :urls => %w[ /js ],
  :root => File.join(File.dirname(__FILE__), 'static'))
#use(
#  Rack::MethodOverride)


get '/style.css' do

  scss :style
end

get '/' do

  haml :index
end

get '/query/:start' do

  content_type 'application/json; charset=utf-8'
  cache_control :public, max_age: 7 * 24 * 3600 # cache for 7d

  json_lines = Index.query(params[:start].downcase, MAX)

  json_lines = json_lines.zip([ ',' ] * json_lines.length).flatten
  json_lines.pop if json_lines.last == ','
  json_lines.unshift('[')
  json_lines.push(']')

  json_lines
end

get '/ip' do

  content_type 'text/plain'

  [ request.ip, env['HTTP_X_REAL_IP'] ].inspect
end

def white_ip?(ip)

  return true if ip == '127.0.0.1'
  return true if ip == '::1'

  begin; File.readlines('white_ips.txt'); rescue []; end.each do |line|

    line = line.split('#').first.strip

    return true if line.length > 0 && ip.match(line)
  end

  false
end

post '/note/:u/:line' do

  content_type 'application/json; charset=utf-8'

  halt '[]' unless white_ip?(env['HTTP_X_REAL_IP'] || request.ip)

  u = params[:u]

  halt '[]' if u.nil?
  halt '[]' unless u.match(/^[a-z0-9]+$/)

  if entry = Index.entry(params[:line].downcase)
    File.open("notes/#{u}.json", 'ab') { |f| f.puts(entry) }
  end

  '[]'
end

