

desc %{
  Generate the data/*.json files from kanjidic.txt and jmdict.txt
}
task :generate do

  require_relative 'lib/index.rb'

  Index.generate
end

desc %{
  Serve the kensaku app locally (port 4567)
}
task :serve do

  sh 'bundle exec ruby kensaku.rb'
end

desc "shortcut for 'rake serve'"
task :s => :serve

desc %{
  Loads the data/*.json (mostly to view load time)
}
task :load do

  require_relative 'lib/mem.rb'
  require_relative 'lib/index.rb'

  puts 'mem ' + mem_to_s
  Index.load
  puts 'mem ' + mem_to_s
end

desc "shortcut for 'rake load'"
task :l => :load

