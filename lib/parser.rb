# encoding: utf-8

require 'mojinizer'


R = /^([^;\s]+)(?:;([^:\s]+))* (?:\[([^;\s]+)(?:;([^:\s]+))*\] )?\/(.+)\/$/
ENTL = /^EntL\d+X?$/

PREX = %w[ ki shi chi ni hi mi ri gi ji bi pi ]

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
      a << nsyl.chars.first
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

def parse_line(l)

  m = R.match(l)

  kanji = [ m[1], *(m[2] ? m[2].split(';') : []) ]

  kana = [ m[3], *(m[4] ? m[4].split(';') : []) ].compact

  syllabs = kana.empty? ? kanji : kana
  syllabs = syllabs.select(&:kana?)
  syllabs = syllabs.collect { |s| s.split('(').first }.uniq

  romaji = syllabs.collect(&:romaji)

  split_romaji = syllabs.collect { |k| k.chars.collect(&:romaji) }
  split_romaji = split_romaji.collect { |s| compact_romaji(s) }

  glosses = m[5].split('/').reject { |g| ENTL.match(g) }

  p kanji
  p kana
  p romaji
  p split_romaji
  p glosses
  puts
end


count = 0
while true
  line = STDIN.readline rescue nil
  break unless line
  count += 1
  parse_line(line)
  break if count == 200
end

#%w[ xya xyo xyu ].each { |k| puts k.hiragana + " " + k.katakana }
#%w[ ya yo yu ].each { |k| puts k.hiragana + " " + k.katakana }
#%w[ tsu h! ].each { |k| puts k.hiragana + " " + k.katakana }
#p "かっこい".chars.collect(&:romaji)
#p compact_romaji("かっこい".chars.collect(&:romaji))

