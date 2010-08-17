require "rubygems"
require "hpricot"
require "open-uri"

doc = Hpricot open "http://tvprofil.net/trenutno/"

if %w(-h --help ? /?).include? ARGV[0]
  puts "Usage: tv.rb [search string]"
  exit
end

##
# Usage: tv [search string]
#

##
# search string nije case sensitive
#

##
# chlist - Array, sadrzi brojeve ili stringove
#        - moze sadrzavati i '*', wildcard

# chlist = (1..4)
chlist = %w(htv* rtl)

trenutno, kanali = doc.search('#tab_trenutno'), []
trenutno.search('.phbox').each{ |x|
  chlist.each { |w|
    if w.class == Fixnum
      kanali << x.at('.phbox') if w == x.at('.phbox')[:rel].to_i
    elsif w.class == String
      if x.at('.phbox > .phkanal > a').inner_text =~ /^#{w.gsub '*', '.+'}$/i
        kanali << x.at('.phbox')
      end
    else
      puts "Error: chlist - wrong format"
    end
  }
}

if ARGV[0]
  findstr = ARGV.join ' '
  @ocurr = nil
  kanali.each { |k|
    found, razmak = [], 0
    k.search('.phrows > div').each { |z|
      time = z.at('span').inner_text
      z.at('span').swap '<span></span>'
      ime  = (z.search('a').count==1) ? z.at('a').inner_text : z.inner_text.strip
      curr = !!(z[:class] =~ /currently/)
      @ocurr_prev = @ocurr
      @ocurr = ime =~ /#{findstr}/i
      if @ocurr
        found << "   ...\n" && razmak=0 if razmak>1
        found << "#{curr ? '=>' : '  '} #{time} - #{ime}\n"
        razmak=0
      end
      razmak += 1
    }
    if !found.empty?
      puts "- #{k.at('.phkanal > a').inner_text}\b\b\b\b"
      puts found.join
    end
  }
else
  kanali.each { |k|
    puts "..... #{k.at('.phkanal > a').inner_text} ....."
    k.search('.phrows > div').each { |z|
      time = z.at('span').inner_text
      z.at('span').swap '<span></span>'
      ime  = (z.search('a').count==1) ? z.at('a').inner_text : z.inner_text.strip
      curr = !!(z[:class] =~ /currently/)
      puts "#{curr ? '> ' : '  '} #{time} - #{ime}"
    }
    puts
  }
end
