#!/usr/bin/env ruby

TV_VER = 'v1.2'

@markf = File.expand_path '~/.tvmarks'

usage = [
  "Usage: tv.rb [search string]",
  "       tv.rb [/mark] [string]",
  "       tv.rb /marks",
  "       tv.rb [-v|-h]"
].join("\n")

if %w(-h --help ? /? /h).include? ARGV[0]
  puts "Version: #{TV_VER}"
  puts usage
  exit
end

if %w(-v --version /v).include? ARGV[0]
  puts "Version: #{TV_VER}"
  exit
end

require "rubygems"
require "hpricot"
require "open-uri"
doc = Hpricot open "http://tvprofil.net/trenutno/"

##
# Usage:
# tv [search string]
# tv mark [str] - dodaje ili brise mark `str` u markfile-u
# tv marks
#

##
# search string nije case sensitive
#

def add_mark mark
  if mark
    begin
      File.open(@markf, 'a'){ |f| f.puts mark }
      puts "Mark '#{mark}' je dodan"
    rescue Errno::ENOENT
      File.open(@markf,'w+'){}
      File.open(@markf, 'a'){ |f| f.puts mark }
    end
  end
end

def marks
  begin
    File.read(@markf).split("\n")
  rescue Errno::ENOENT
    File.open(@markf,'w+'){|f|}
    File.read(@markf).split("\n")
  end
end

def del_mark mark
  if mark
    m = marks
    if m.include? mark
      m = m - [mark]
      File.open(@markf, 'w'){ |f| f.puts m.join "\n" }
      puts "Mark '#{mark}' je obrisan"
    else
      puts "Mark file ne sadrzi: #{mark}"
    end
  end
end

if %w(/mark).include? ARGV[0]
  if x=ARGV[1]
    re = /^[a-zA-Z0-9_\-\+]+$/
    if x =~ re
      if marks.include? x
        del_mark x
      else
        add_mark ARGV[1]
      end
    else
      puts "Mark je krivog formata!"
      puts re.inspect
    end
  else
    puts usage
  end
  exit
elsif %w(/marks).include? ARGV[0]
  puts marks.join("\n")
  exit
end

@marks = marks()

def marked? str
  @marks.find {|m| str =~ /#{m}/i }
end

##
# chlist - Array, sadrzi brojeve (ID kanala) ili stringove (naziv)
#        - moze sadrzavati i '*', wildcard

# chlist = (1..4)
chlist = %w(htv* rtl nova\ tv)

trenutno, kanali = doc.search('#tab_trenutno'), []
trenutno.search('.phbox').each{ |x|
  chlist.each { |w|
    if w.class == Fixnum
      kanali << x.at('.phbox') if w == x.at('.phbox')[:rel].to_i
    elsif w.class == String
      kanali << x.at('.phbox') if x.at('.phbox > .phkanal > a').inner_text =~ /^#{w.gsub '*', '.+'}$/i
    else
      puts "Error: chlist - wrong format"
    end
  }
}

if ARGV[0]
  findstr = ARGV.join ' '
  @ocurr = nil
  @found = 0
  kanali.each { |k|
    found, razmak = [], 0
    k.search('.phrows > div').each { |z|
      time = z.at('span').inner_text
      z.at('span').swap '<span></span>'
      ime  = (z.search('a').count==1) ? z.at('a').inner_text : z.inner_text.strip
      curr = !!(z[:class] =~ /currently/)
      @ocurr_prev = @ocurr
      @ocurr = ime =~ /#{findstr.gsub /\+/, '.*'}/i
      if @ocurr
        found << "   ...\n" && razmak=0 if razmak>1
        mr = marked? ime
        found << "#{curr ? '=>' : '  '} #{'[[ ' if mr}#{time} - #{ime}#{' ]]' if mr}\n"
        razmak=0
        @found+=1
      end
      razmak += 1
    }
    if !found.empty?
      puts "- #{k.at('.phkanal > a').inner_text}\b\b\b\b"
      puts found.join
    end
  }
  if @found==0
    puts "Nije pronadjen entry sa #{findstr}"
  end
else
  kanali.each { |k|
    puts "..... #{k.at('.phkanal > a').inner_text} ....."
    k.search('.phrows > div').each { |z|
      time = z.at('span').inner_text
      z.at('span').swap '<span></span>'
      ime  = (z.search('a').count==1) ? z.at('a').inner_text : z.inner_text.strip
      curr = !!(z[:class] =~ /currently/)
      mr   = marked? ime
      puts "#{curr ? '> ' : '  '} #{'[[ ' if mr}#{time} - #{ime}#{' ]]' if mr}"
    }
    puts
  }
end
