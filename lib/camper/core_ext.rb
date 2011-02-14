require 'parsedate'
require 'date'

class Object
    def blank?
        respond_to?(:empty?) ? empty? : !self
    end
    def upcase
        "dummy string to fix bug of sequel"
    end
    ##
    #   @person ? @person.name : nil
    # vs
    #   @person.try(:name)
    def try(method, *a)
        send method, *a if respond_to? method
    end
end
module Enumerable
   def cross arg
       inject([]){|m, v| m<<[arg, v]}
   end
end
#useful for returning default values for enum find/detect
class Array
    def found?(e)
        ifnone = proc{ (e < self.first)?self.first : (e > self.last)?self.last : nil}
        find(ifnone){|i| i==e}
    end
end
class Numeric
   def init_toggle
      @n=0
   end
   alias acts_as_toggle init_toggle
   def toggle
      @n=1-@n
   end
end
class String
    regex = 'https?://([-\w\.]+)+(:\d+)?(/([\w/_\-\.+%,#@]*(\?\S+)?)?)?'
    RLINK = Regexp.compile(regex)
    def linkify
        self.gsub RLINK, '<a href="\0" target="_blank", class="url">link&crarr;</a>'
    end
    def h
         gsub!("<", "&lt;")
         gsub!(">", "&gt;")
         self
    end
    def to_html
        self.gsub(/(\s*\n)+/, '<br />')
    end
    def to_bold
        self.gsub(/(\*)([^\s][^*]+[^\s])\1/, '<b>\2</b>')
    end
    alias_method :to_html_br, :to_html

    def to_markup
        self.linkify.to_html_br.to_bold
    end
    def wrap(max_width = 20)
        (self.length < max_width) ?
        self :
        self.scan(/.{1,#{max_width}}/).join("\n")
    end
    def to_date
        Date.new(*ParseDate.parsedate(self).compact)
    end
end


module TimeToWords
    def to_words(timestamp=self)
        minutes = (((Time.now - timestamp).abs)/60).round
        return nil if minutes < 0
        case minutes
        when 0               then 'less than a minute ago'
        when 0..4            then 'less than 5 minutes ago'
        when 5..14           then 'less than 15 minutes ago'
        when 15..29          then 'less than 30 minutes ago'
        when 30..59          then 'more than 30 minutes ago'
        when 60..119         then 'more than 1 hour ago'
        when 120..239        then 'more than 2 hours ago'
        when 240..479        then 'more than 4 hours ago'
        else
            if minutes.abs < 182*1440
               timestamp.strftime('%I:%M %p %d-%b')
            else
               timestamp.strftime('%I:%M %p %d-%b-%Y')
            end
        end
    end
    def to_h  #(date)
        date = self.send(:to_date) rescue self
        days = (date - Date.today).to_i

        return 'today'     if days >= 0 and days < 1
        return 'tomorrow'  if days >= 1 and days < 2
        return 'yesterday' if days >= -1 and days < 0

        return "in #{days} days"      if days.abs < 60 and days > 0
        return "#{days.abs} days ago" if days.abs < 60 and days < 0

        return date.strftime('%A, %B %e') if days.abs < 182
        return date.strftime('%A, %B %e, %Y')
    end

end

class Time
    include TimeToWords
end

class Hash
    def compact!
        self.tap{|x|x.delete_if{|key, value| value.blank? }}
    end
    def to_params
        params = ''
        stack = []

        each do |k, v|
            if v.is_a?(Hash)
                stack << [k,v]
            elsif v.is_a?(Array)
                stack << [k,Hash.from_array(v)]
            else
                params << "#{k}=#{v}&"
            end
        end

        stack.each do |parent, hash|
            hash.each do |k, v|
                if v.is_a?(Hash)
                    stack << ["#{parent}[#{k}]", v]
                else
                    params << "#{parent}[#{k}]=#{v}&"
                end
            end
        end
        params.chop!
        params
    end

    def self.from_array(array = [])
        h = Hash.new
        array.size.times do |t|
            h[t] = array[t]
        end
        h
    end

end
#
