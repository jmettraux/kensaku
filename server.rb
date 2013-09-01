
require 'sinatra'
require 'haml'
require 'compass'

require_relative 'lib/parser.rb'

$roots = {}
#load_words
#load_kanji
sort_roots


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
use(Rack::MethodOverride)

get '/style.css' do

  scss :style
end

get '/' do

  haml :index
end

get '/query/:start' do

  results = ($roots[params[:start].downcase] || []).take(MAX)

  content_type 'application/json; charset=utf-8'
  cache_control :public, max_age: 7 * 24 * 3600 # cache for 7d

  Rufus::Json.encode(results.collect(&:to_h))
end

get '/ip' do

  content_type 'text/plain'

  [ request.ip, env['X-REAL-IP'] ].inspect
end

def white_ip?(ip)

  return true if ip == '127.0.0.1'
  return true if ip == '::1'

  begin; File.readlines('white_ips.txt'); rescue []; end.each do |line|

    return true if ip.match(line)
  end

  false
end

post '/note/:u/:start/:line' do

  content_type 'application/json; charset=utf-8'

  halt '[]' unless white_ip?(request.ip)

  u = params[:u]

  halt '[]' if u.nil?
  halt '[]' unless u.match(/^[a-z0-9]+$/)

  entries = ($roots[params[:start].downcase] || []).take(MAX)
  entry = entries.find { |e| e.line == params[:line] }

  halt '[]' unless entry

  File.open("notes/#{u}.json", 'ab') { |f| f.puts(entry.to_json) }

  '[]'
end

