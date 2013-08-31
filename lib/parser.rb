# encoding: utf-8

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

require 'rufus-json/automatic'
require 'mojinizer'


class Entry

  attr_accessor :line, :kanji, :kana, :romaji, :split_romaji, :glosses

  R = /^([^;\s]+)(?:;([^:\s]+))* (?:\[([^;\s]+)(?:;([^:\s]+))*\] )?\/(.+)\/$/
  ENTL = /^EntL\d+X?$/
  VOWELS = %w[ a e i o u ]
  CIRCLES = %w[ ➀ ➁ ➂ ➃ ➄ ➅ ➆ ➇ ➈ ➉ ]
  #FINAL_TSU = /h!$/

  def self.parse_edict2_entry(line, s)

    e = Entry.new

    e.line = "e#{line}"

    m = R.match(s)

    e.kanji = [ m[1], *(m[2] ? m[2].split(';') : []) ]
    e.kanji = e.kanji.collect { |k| k.split('(').first }.uniq

    e.kana = [ m[3], *(m[4] ? m[4].split(';') : []) ].compact
    e.kana = e.kana.collect { |k| k.split('(').first }.uniq

    syls = e.kana.empty? ? e.kanji : e.kana
    syls = syls.collect { |s| s.gsub(/・/, '') }
    e.romaji = syls.collect(&:romaji)
    e.romaji = e.romaji.reject { |s| s == '' || s.chars.first.japanese? }
    #e.romaji = e.romaji.collect { |s| s.match(FINAL_TSU) ? s[0..-3] + 'tsu' : s }

    e.split_romaji = e.romaji.collect { |r| split(r) }

    e.glosses =
      m[5].split('/').reject { |g|

        g == '(P)' || ENTL.match(g)

      }.inject([]) { |a, gs|

        last = a.last || ''

        if a.empty? || gs.match(/\(\d+\)/)
          a << gs
        else
          a[a.size - 1] = last + '; ' + gs
        end

        a

      }.collect { |g|

        (1..10).each { |i| g.gsub!(/\(#{i}\)/, CIRCLES[i - 1]) }

        g
      }

    e
  end

  def self.parse_kanjidic_entry(line, s)

    i = s.index('{')
    head = s[0..i - 2]
    tail = s[i..-2]

    ss = head.split(' ')

    e = Entry.new

    e.line = "k#{line}"
    e.kanji = [ ss.shift ]
    e.glosses = []
    e.glosses << ss.select { |str| ! str.chars.first.kana? }.join(' ')
    e.kana = ss.select { |str| str.chars.first.kana? }
    e.romaji = e.kana.collect { |k| k.romaji }.uniq
    e.split_romaji = e.romaji.collect { |r| split(r) }

    e.glosses.concat(
      tail.split('{').collect { |x|
        x.gsub('}', '').strip
      }.reject { |x|
        x.length < 1
      }
    )

    e
  end

  def to_h

    {
      'li' => @line,
      'ki' => @kanji,
      'ka' => @kana,
      'ro' => @romaji,
      #'sr' => @split_romaji,
      'gs' => @glosses
    }
  end

  def to_json

    Rufus::Json.dump(to_h)
  end

  def hash

    @line.hash
  end

  def eql?(o)

    o.is_a?(Entry) && o.hash == self.hash
  end

  protected

  def self.split(s)

    #raise "not romaji >#{s}<" unless s.match(/^[a-z\.]+$/)

    s = s.split('.').first
      # for kanjidic "hiro.maru" and co

    return [] if s == nil

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

def index_entry(e)

  e.split_romaji.each do |sr|
    s = sr.shift
    loop do
      ($roots[s] ||= []) << e
      n = sr.shift
      break unless n
      s = s + n
    end
  end
end

def load_words

  puts "data/edict2.txt"

  t = Time.now
  count = 0

  File.readlines('data/edict2.txt').each_with_index do |s, l|

    next if s.match(/^　？？？/) # copyright

    index_entry(Entry.parse_edict2_entry(l + 1, s))

    count = l + 1
  end

  puts "data/edict2.txt  loaded #{count} entries, took #{Time.now - t}s"
end

def load_kanji

  puts "data/kanjidic.txt"

  t = Time.now
  count = 0

  File.readlines('data/kanjidic.txt').each_with_index do |s, l|

    next if s.match(/^#/) # copyright

    index_entry(Entry.parse_kanjidic_entry(l + 1, s))

    count = l + 1
  end

  puts "data/kanjidic.txt  loaded #{count} entries, took #{Time.now - t}s"
end

def sort_roots

  t = Time.now

  puts "#{$roots.size} roots"
  count = $roots.values.inject(0) { |count, entries| count + entries.size }
  puts "#{count} entry references"

  $roots.each do |k, v|

    q = /^#{k}/

    s0 = v.size
    v.uniq!
    s1 = v.size
    v.sort_by! { |e| e.romaji.find { |ro| ro.match(q) } }
  end

  count = $roots.values.inject(0) { |count, entries| count + entries.size }
  puts "#{count} entry references"
  puts "took #{Time.now - t}s"
end

