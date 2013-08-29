# encoding: utf-8

require 'pp'
require 'rufus-json/automatic'
require 'mojinizer'


class Entry

  attr_reader :id, :kanji, :kana, :romaji, :split_romaji, :glosses

  R = /^([^;\s]+)(?:;([^:\s]+))* (?:\[([^;\s]+)(?:;([^:\s]+))*\] )?\/(.+)\/$/
  ENTL = /^EntL\d+X?$/

  PREX = %w[ ki shi chi ni hi mi ri gi ji bi pi te de u vu ]

  def initialize(id, line)

    @id = id

    m = R.match(line)

    @kanji = [ m[1], *(m[2] ? m[2].split(';') : []) ]

    @kana = [ m[3], *(m[4] ? m[4].split(';') : []) ].compact

    syls = @kana.empty? ? kanji : kana
    syls = syls.select(&:kana?)
    syls = syls.collect { |s| s.split('(').first }.uniq

    @romaji = syls.collect(&:romaji)
    @split_romaji = @romaji.collect { |r| split(r) }

    @glosses = m[5].split('/').reject { |g| ENTL.match(g) }
  end

  def to_h

    {
      'id' => id,
      'ki' => kanji,
      'ka' => kana,
      'ro' => romaji,
      'sr' => split_romaji,
      'gs' => glosses
    }
  end

  protected

  VOWELS = %w[ a e i o u ]

  def split(s)

    a = []
    cs = s.chars.to_a

    loop do
      c = cs.shift
      nc = cs.first
      break unless c
      if VOWELS.include?(c)
        a << c
      elsif VOWELS.include?(nc)
        cs.shift
        a << c + nc
      elsif c == nc || c == 'n'
        a << c
      else
        a << c + (cs.shift || '') + (cs.shift || '')
      end
    end

    a
  end
end


def self_ps
  # pid stat time sl re pagein vsz rss lim tsiz pcpu pmem command
  cols = %w[ vsz rss lim tsiz pcpu pmem ]
  ps = `ps -o #{cols.join(',')} #{$$}`.split("\n").last.split(' ')
  cols.inject({}) { |h, k| h[k.intern] = ps.shift; h }
end
def pmem(msg)
  ps = self_ps
  p [ msg, "#{ps[:vsz].to_i / 1024}k", ps[:pmem] ]
end
pmem 'starting'


t = Time.now
a = []
while true
  line = STDIN.readline rescue nil
  break unless line
  a << Entry.new(a.size, line)
end
d = Time.now - t

puts "done, #{a.size} entries, took #{d} seconds."
pmem 'over.'
exit 0


depth = 4
maxlines = 35

t = Time.now
count = 0
while true
  line = STDIN.readline rescue nil
  break unless line
  e = Entry.new(count, line)
  count += 1

  next if e.split_romaji.size < 1

  e.split_romaji.each do |sr|

    (1..depth).each do |l|

      break if l > sr.length

      #p sr[0, l]

      prefix = sr[0, l].join
      fname = "entries/#{prefix}.json"

      lines = File.exist?(fname) ? File.readlines(fname).size : 0
      puts "#{count} #{fname}: #{lines}" if lines > 0

      next if l < sr.length && l < depth && lines >= maxlines

      if fname.index('x') # remove me at some point...
        pp e.to_h
        raise "found 'x' in '#{fname}'"
      end

      File.open(fname, 'ab') { |f| f.puts(Rufus::Json.dump(e.to_h)) }
    end
  end
end
d = Time.now - t

puts "done, #{count} entries, took #{d} seconds."
  #
  # done, 167060 entries, took 56.486152348 seconds (just reading)

