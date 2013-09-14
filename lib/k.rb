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

require_relative './index.rb'
Index.load


module Krad

  def self.load

    non_displayable_radicals =
      %w[ R201a2 R2e85 R2e8c R2eb9 R2ebe R2ecf R2ed6 Rfa66 ]

    kans = {}
    rads = {}

    File.readlines('data/kradfile-u').each do |line|

      line = line.strip
      next if line == '' || line.match(/^#/)

      radicals = line.split(/[: ]+/)

      kanji = radicals.shift
      kcode = "U#{kanji.ord.to_s(16)}"

      rcodes = radicals.collect { |r| "R#{r.ord.to_s(16)}" }
      rcodes = rcodes - non_displayable_radicals

      next unless Index.ji(kcode)

      kans[kcode] = rcodes

      rcodes.each do |rcode|
        (rads[rcode] ||= []) << kcode
      end
    end

    [ kans, rads ]
  end
end

ks, rs = Krad.load

puts "kradfile:  #{ks.size}"
puts "kanjidic:  #{Index.kanji_keys.size}"

