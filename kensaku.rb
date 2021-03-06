#--
# Copyright (c) 2013-2013, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

require 'sinatra'
require 'haml'
require 'compass'

require 'rufus-json/automatic'


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

  set :protection, :except => [ :json_csrf ]
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
  cache_control :public, max_age: 2 * 24 * 3600 # cache for 2d

  json_lines = Index.query(params[:start].romaji.downcase, MAX)

  json_lines = json_lines.zip([ ',' ] * json_lines.length).flatten
  json_lines.pop if json_lines.last == ','
  json_lines.unshift('[')
  json_lines.push(']')

  json_lines
end

get '/ji/:code' do

  content_type 'application/json; charset=utf-8'
  cache_control :public, max_age: 2 * 24 * 3600 # cache for 2d

  Index.ji(params[:code])
end

get '/jis/:codes' do

  content_type 'application/json; charset=utf-8'
  cache_control :public, max_age: 2 * 24 * 3600 # cache for 2d

  codes = params[:codes].split(',')

  jis =
    codes.collect { |c|
      Index.ji(c)
    }.sort_by { |ji|
      ji.match(/ S(\d+)/)[1].to_i
    }

  [ '[', jis.join(','), ']' ]
end

get '/locations/:code' do

  content_type 'application/json; charset=utf-8'
  cache_control :public, max_age: 2 * 24 * 3600 # cache for 2d

  ji = Index.ji(params[:code])

  return '[]' unless ji

  r = Rufus::Json.decode(ji)['lo'].map { |l| l.map { |c| Index.ji("E#{c}") } }

  [
    '[[', r[0].join(','), '],',
    '[', r[1].join(','), '],',
    '[', r[2].join(','), ']]'
  ]
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

  u = params[:u].split('.').last

  fname = "marks/#{u}.json"

  marks = []
  marks = File.readlines(fname) if File.exist?(fname)
  marks = marks.collect { |m| m.strip.inspect }.join(',')

  [ 'var marks = [', marks, '];' ]
end

get '/radicals' do

  content_type 'application/json; charset=utf-8'
  cache_control :public, max_age: 2 * 24 * 3600 # cache for 2d

  [ 'var radicals = ', File.read('data/radicals.json'), "; \n" ]
end

