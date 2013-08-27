
require 'mojinizer'

R = /^([^;\s]+)(?:;([^:\s]+))* (?:\[([^;\s]+)(?:;([^:\s]+))*\] )?\/(.+)\/$/
ENTL = /^EntL\d+X?$/

def parse_line(l)

  m = R.match(l)

  kanji = [ m[1], *(m[2] ? m[2].split(';') : []) ]

  kana = [ m[3], *(m[4] ? m[4].split(';') : []) ].compact

  romaji = kana.collect(&:romaji)
  romaji = kanji.select(&:kana?).collect(&:romaji) if romaji.empty?
  romaji = romaji.collect { |s| s.split('(').first }.uniq

  glosses = m[5].split('/').reject { |g| ENTL.match(g) }

  p kanji
  p kana
  p romaji
  p glosses
  puts
end

count = 0
while true
  line = STDIN.readline rescue nil
  break unless line
  count += 1
  parse_line(line)
  break if count == 100
end

