
require 'sinatra'
require 'haml'
require 'compass'


#
# kensaku index loading
#

require_relative 'lib/index.rb'
Index.load

MAX = 98


#
# sinatra configuration
#

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


#
# helpers
#

helpers do

  def param_u

    if u = params[:u]
      u.inspect
    else
      'undefined'
    end
  end
end


#
# routes
#

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

def whitelisted_ip?(ip)

  return true if ip == '127.0.0.1'
  return true if ip == '::1'

  begin; File.readlines('ip_whitelist.txt'); rescue []; end.each do |line|

    line = line.split('#').first.strip

    return true if line.length > 0 && ip.match(line)
  end

  puts "not whitelisted #{ip}"; $stdout.flush

  false
end

post '/mark/:u/:id' do

  content_type 'application/json; charset=utf-8'

  unless whitelisted_ip?(env['HTTP_X_REAL_IP'] || request.ip)
    status 403
    halt ''
  end

  u = params[:u]

  halt '[]' if u.nil?
  halt '[]' unless u.match(/^[a-z0-9]+$/)

  id = params[:id]

  if entry = Index.entry(id)
    File.open("marks/#{u}.json", 'ab') { |f| f.puts(id) }
  end

  '[]'
end

get '/marks/:u' do

  marks = begin; File.readlines("marks/#{params[:u]}.json"); rescue []; end
  marks = marks.collect { |m| m.strip.inspect }.join(',')

  [ 'var marks = [', marks, '];' ]
end

