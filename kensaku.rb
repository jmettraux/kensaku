
require 'sinatra'
require 'haml'
require 'compass'

configure do

  Compass.configuration do |c|
    c.project_path = File.dirname(__FILE__)
    c.sass_dir = 'views'
  end

  set :haml, :format => :html5
  set :sass, Compass.sass_engine_options
  set :scss, Compass.sass_engine_options
end

#get '/sass.css' do; sass :sass_file; end
get '/scss.css' do; sass :scss_file; end

get '/' do

  haml :index
end

