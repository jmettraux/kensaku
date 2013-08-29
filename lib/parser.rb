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

require 'pp'
#require 'rufus-json/automatic'
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


t = Time.now
i = 0
while true
  line = STDIN.readline rescue nil
  break unless line
  e = Entry.new(i, line)
  i = i + 1
end
d = Time.now - t

puts "done, #{i} entries, took #{d} seconds."

