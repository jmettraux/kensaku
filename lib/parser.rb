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

  attr_reader :line, :kanji, :kana, :romaji, :split_romaji, :glosses

  R = /^([^;\s]+)(?:;([^:\s]+))* (?:\[([^;\s]+)(?:;([^:\s]+))*\] )?\/(.+)\/$/
  ENTL = /^EntL\d+X?$/

  PREX = %w[ ki shi chi ni hi mi ri gi ji bi pi te de u vu ]

  def initialize(line, s)

    @line = line

    m = R.match(s)

    @kanji = [ m[1], *(m[2] ? m[2].split(';') : []) ]
    @kanji = @kanji.collect { |k| k.split('(').first }.uniq

    @kana = [ m[3], *(m[4] ? m[4].split(';') : []) ].compact
    @kana = @kana.collect { |k| k.split('(').first }.uniq

    syls = @kana.empty? ? kanji : kana

    @romaji = syls.collect(&:romaji)
    @split_romaji = @romaji.collect { |r| split(r) }

    @glosses =
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
      }
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

    @line
  end

  def eql?(o)

    o.is_a?(Entry) && o.hash == self.hash
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

def load_and_index(path)

  #t = Time.now
  roots = {}
  count = 0

  File.readlines('data/edict2.txt').each_with_index do |s, i|

    e = Entry.new(i + 1, s)

    e.split_romaji.each do |sr|
      s = sr.shift
      loop do
        (roots[s] ||= []) << e
        n = sr.shift
        break unless n
        s = s + n
      end
    end

    count = i + 1
  end

  roots.each do |k, v|

    q = /^#{k}/

    s0 = v.size
    v.uniq!
    s1 = v.size
    v.sort_by! { |e| e.romaji.find { |ro| ro.match(q) } }
  end

  [ roots, count ]
end

