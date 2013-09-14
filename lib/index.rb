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

  attr_accessor :id, :kanji, :kana, :romaji, :split_romaji, :glosses, :children

  R_E = /^([^;\s]+)(?:;([^:\s]+))* (?:\[([^;\s]+)(?:;([^:\s]+))*\] )?\/(.+)\/$/
  R_ENTL = /^EntL(\d+)X?$/
  R_UNICODE = /^U[0-9a-f]+$/
  VOWELS = %w[ a e i o u ]
  CIRCLES = %w[ ➀ ➁ ➂ ➃ ➄ ➅ ➆ ➇ ➈ ➉ ]

  def self.parse(s)

    return nil if s.match(/^　？？？/) # copyright
    return nil if s.match(/^#/) # copyright

    if m = R_E.match(s)
      parse_edict2_entry(m, s)
    else
      parse_kanjidic_entry(s)
    end
  end

  def self.parse_edict2_entry(m, s)

    e = Entry.new

    e.kanji = [ m[1], *(m[2] ? m[2].split(';') : []) ]
    e.kanji = e.kanji.collect { |k| k.split('(').first }.uniq

    e.kana = [ m[3], *(m[4] ? m[4].split(';') : []) ].compact
    e.kana = e.kana.collect { |k| k.split('(').first }.uniq

    e.romaji = filter_romaji(e.kana.empty? ? e.kanji : e.kana)
    e.split_romaji = e.romaji.collect { |r| split_romaji(r) }

    m5 = m[5].split('/')

    e.id =
      m5.collect { |g|
        if m = R_ENTL.match(g)
          "E#{m[1]}"
        else
          nil
        end
      }.compact.first

    e.glosses =
      m5.reject { |g|

        g == '(P)' || R_ENTL.match(g)

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

  def self.parse_kanjidic_entry(s)

    i = s.index('{')
    head = s[0..i - 2]
    tail = s[i..-2]

    ss = head.split(' ')

    e = Entry.new

    e.id = ss.find { |str| str.match(R_UNICODE) }
    e.kanji = [ ss.shift ]
    e.glosses = []
    e.glosses << ss.select { |str| ! str.chars.first.kana? }.join(' ')
    e.kana = ss.select { |str| str.chars.first.kana? }
    e.romaji = filter_romaji(e.kana)
    e.split_romaji = e.romaji.collect { |r| split_romaji(r) }

    e.glosses <<
      tail.split('{').collect { |x|
        x.gsub('}', '').strip
      }.reject { |x|
        x.length < 1
      }.join('; ')

    e
  end

  def to_h

    h =
      {
        'id' => @id,
        'ki' => @kanji,
        'ka' => @kana,
        'ro' => @romaji,
        'gs' => @glosses
      }
    h['cn'] = @children if @children

    h
  end

  def to_json

    Rufus::Json.dump(to_h)
  end

  def hash

    @id.hash
  end

  def eql?(o)

    o.is_a?(Entry) && o.hash == self.hash
  end

  def type

    @id[0, 1] == 'U' ? 'k' : 'e'
  end

  def kanji?

    type == 'k'
  end

  protected

  def self.filter_romaji(ss)

    ss.collect { |s|
      s.romaji
    }.collect { |s|
      s.gsub(/・/, '')
    }.reject { |s|
      s == '' || s.chars.first.japanese?
    }.collect { |s|
      s.gsub('h!', 'ts')
    }.collect { |s|
      s.gsub('xtsu', 'ts')
    }.uniq
  end

  def self.split_romaji(s)

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

module Index

  def self.index_entry(e)

    @@kanji[e.id] = e if e.kanji?

    e.split_romaji.each do |sr|

      s = sr.shift
      loop do
        (@@roots[s] ||= []) << e
        n = sr.shift
        break unless n
        s = s + n
      end
    end
  end

  def self.translate_file(source, destination)

    t = Time.now
    count = 0

    puts "translating from #{source} to #{destination}..."

    FileUtils.rm_f(destination)

    File.open(destination, 'ab') do |f|
      File.readlines(source).each do |s|
        e = Entry.parse(s)
        next if e == nil
        count = count + 1
        index_entry(e)
        f.puts(e.to_json)
        print '.' if count % 500 == 0
      end
    end

    puts "\ntranslated #{count} items, took #{Time.now - t}s"
  end

  def self.read_krad_file(fname)

    non_displayable_radicals =
      %w[ R201a2 R2e85 R2e8c R2eb9 R2ebe R2ecf R2ed6 Rfa66 ]

    count = 0

    File.readlines(fname).each do |line|

      line = line.strip
      next if line == '' || line.match(/^#/)

      radicals = line.split(/[: ]+/)

      kanji = radicals.shift
      kcode = "U#{kanji.ord.to_s(16)}"

      rcodes = radicals.collect { |r| "R#{r.ord.to_s(16)}" }
      rcodes = rcodes - non_displayable_radicals

      entry = @@kanji[kcode]

      next unless entry

      count = count + 1

      (entry.children ||= []) << rcodes

      rcodes.each do |rcode|
        (@@radicals[rcode] ||= []) << kcode
      end
    end

    puts "#{count} kanji, #{@@radicals.size} radicals"
  end

  def self.sort_roots

    t = Time.now

    puts "sorting roots..."
    puts "#{@@roots.size} roots"
    count = @@roots.values.inject(0) { |count, entries| count + entries.size }
    puts "#{count} entry references"

    @@roots.keys.each do |k|

      q = /^#{k}/

      @@roots[k] =
        @@roots[k].uniq.sort_by { |e|
          e.romaji.find { |ro| ro.match(q) }
        }.collect { |e|
          e.id
        }
    end

    count = @@roots.values.inject(0) { |count, entries| count + entries.size }
    puts "#{count} entry references"
    puts "took #{Time.now - t}s"
  end

  def self.write(data, fname)

    t = Time.now

    File.open(fname, 'wb') do |f|
      f.puts(Rufus::Json.dump(data))
    end

    puts "wrote #{fname}, took #{Time.now - t}s"
  end

  def self.generate

    @@kanji = {}
    @@roots = {}
    @@radicals = {}

    translate_file('data/edict2.txt', 'data/edict2.json')
    translate_file('data/kanjidic.txt', 'data/kanjidic.json')
    read_krad_file('data/kradfile-u')

    sort_roots
    write(@@roots, 'data/roots.json')
    write(@@radicals, 'data/radicals.json')
  end

  R_ID = /^{\"id\":\"([a-zA-Z0-9]+)\"/

  def self.load_file(fname)

    t = Time.now

    puts "loading #{fname}..."

    File.readlines(fname).each do |line|
      id = line.match(R_ID)[1]
      @@index[id] = line.chop
    end

    puts "loaded #{fname}, took #{Time.now - t}s"
  end

  def self.load_r(fname)

    t = Time.now

    puts "loading #{fname}..."

    r = Rufus::Json.decode(File.read(fname))

    puts "loaded #{fname}, took #{Time.now - t}s"

    r
  end

  def self.load

    @@index = {}

    load_file('data/edict2.json')
    load_file('data/kanjidic.json')

    @@roots = load_r('data/roots.json')
    @@radicals = load_r('data/radicals.json')
  end

  def self.entry(id)

    @@index[id]
  end

  def self.kanji_keys

    @@index.keys.select { |k| k[0, 1] == 'U' }
  end

  def self.query(start, max)

    (@@roots[start] || []).take(max).collect { |l| entry(l) }
  end

  def self.ji(id)

    @@index[id]
  end
end

