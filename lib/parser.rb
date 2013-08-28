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

    @split_romaji = syls.collect { |k| k.chars.collect(&:romaji) }
    @split_romaji = @split_romaji.collect { |s| compact_romaji(s) }

    @glosses = m[5].split('/').reject { |g| ENTL.match(g) }
  end

  def merge_romaji(syl0, syl1)

    if syl0 == 'ji' || syl0 == 'chi' || syl0 == 'shi'
      syl0.chars.first + syl1.chars.to_a.last
    elsif syl0 == 'u'
      'v' + syl1.chars.to_a.last
    else
      syl0.chars.first + syl1.chars.to_a[1..-1].join
    end
  end

  def compact_romaji(syllables)

    a = []

    while syllables.length > 0

      syl = syllables.shift
      nsyl = syllables.first

      if syl == 'h!'
        if nsyl
          a << nsyl.chars.first
        else
          a << 'tsu'
        end
      elsif nsyl && PREX.index(syl)
        if nsyl.chars.first == 'x'
          syllables.shift
          a << merge_romaji(syl, nsyl)
        else
          a << syl
        end
      elsif syl.chars.first == 'x' # a ga a na (Hiroshima dialect)
        a << syl.chars.to_a[1..-1].join
      else
        a << syl
      end
    end

    a
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
end

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

