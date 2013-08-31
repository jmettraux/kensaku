
require 'sinatra'
require 'haml'
require 'compass'

require_relative 'lib/parser.rb'

t = Time.now
$roots, count = load_and_index('data/edict2.txt')

puts "loaded and indexed #{count} entries, took #{Time.now - t} seconds"

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
  :urls => %w[ /images /js ],
  :root => File.join(File.dirname(__FILE__), 'static'))
#use(Rack::MethodOverride)

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

