require 'date'
def days_in_month(year, month)
  (Date.new(year, 12, 31) << (12-month)).day
end
class Date
   def self.days_in_month(year, month)
     (new(year, 12, 31) << (12-month)).day
   end
end
toggle=0
(2008..2011).each do |y|
   p y
   (1..12).each do |m|      
      dim = Date.days_in_month(y, m)
      toggle=1-toggle
      jchar="."
      jchar="+" if toggle.even?
      print ["[%02d]" % m, (" %02d "*dim) % (1..dim).to_a].join(jchar)
   end
   puts
end