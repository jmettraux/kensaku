
require 'sinatra'
require 'haml'
require 'compass'

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

