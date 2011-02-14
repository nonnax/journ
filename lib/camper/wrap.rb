#!/opt/local/bin/ruby
class String
  # Replace the second of three capture groups with the given block.
  def midsub(regexp, &block)
    self.gsub(regexp) { $1 + yield($2) + $3 }
  end

   def xxwrap(width=80, string="\n")
     self.midsub(%r{(\A|</pre>)(.*?)(\Z|<pre(?: .+?)?>)}im) do |outside_pre|  # Not inside <pre></pre>
       outside_pre.midsub(%r{(\A|>)(.*?)(\Z|<)}m) do |outside_tags|  # Not inside < >, either
         outside_tags.gsub(/(\S{#{width}})(?=\S)/) { "#$1#{string}" }
       end
     end
   end

end


class String

   def wrap(max_width = 20)
     (self.length < max_width) ?
       self :
       self.scan(/.{1,#{max_width}}/).join("\n")
   end

  def xwrap(width, hanging_indent = 0, magic_lists = false)
    lines = self.split(/\n/)

    lines.collect! do |line|

      if magic_lists
        line =~ /^([\s\-\d\.\:]*\s)/
      else
        line =~ /^([\s]*\s)/
      end

      indent = $1.length + hanging_indent rescue hanging_indent

      buffer = ""
      first = true

      while line.length > 0
        first ? (i, first = 0, false) : i = indent
        pos = width - i

        if line.length > pos and line[0..pos] =~ /^(.+)\s/
          subline = $1
        else
          subline = line[0..pos]
        end
        buffer += " " * i + subline + "\n"
#        line.tail!(subline.length)
        line.tail!(subline.length-1)
      end
      buffer[0..-2]
    end

    lines.join("\n")

  end

  def tail!(pos)
    self[0..pos] = ""
    strip!
  end

end
