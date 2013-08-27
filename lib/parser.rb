# encoding: utf-8

require 'mojinizer'


class Entry

  attr_reader :id, :kanji, :kana, :romaji, :split_romaji, :glosses

  R = /^([^;\s]+)(?:;([^:\s]+))* (?:\[([^;\s]+)(?:;([^:\s]+))*\] )?\/(.+)\/$/
  ENTL = /^EntL\d+X?$/

  PREX = %w[ ki shi chi ni hi mi ri gi ji bi pi ]

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
      else
        a << syl
      end
    end
    a
  end
end

count = 0
while true
  line = STDIN.readline rescue nil
  break unless line
  e = Entry.new(count, line)
  count += 1
end

