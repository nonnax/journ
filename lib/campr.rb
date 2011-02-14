# campr.rb
# camper gem's little brother
# includes the same simplified deployment method for running camping apps and using sequel for models module
#  ...nothing else
# ex.
# require 'campr'
# Camping.goes YourApp, :database=>'yourapp.db'
# ...dump your sh*t here
# Camping.start
# voila!
#
#
#
%w[camper/core_ext sequel sequel/extensions/pagination sequel/plugins/timestamps camping camping/session tagz camper/camper_caching camper/camper_pagination].each{|l| require l}

class Hash
   def method_missing(m,*a)
      m.to_s=~/=$/?self[$`]=a[0]:a==[]?self[m]:super
   end
#   undef id, type
end
# A Rack middleware for reading X-Sendfile. Should only be used in development.
class XSendfile

   HEADERS = [
      "X-Sendfile",
      "X-Accel-Redirect",
      "X-LIGHTTPD-send-file"
   ]

   def initialize(app)
      @app = app
   end

   def call(env)
      status, headers, body = @app.call(env)
      headers = Rack::Utils::HeaderHash.new(headers)
      if header = HEADERS.detect { |header| headers.include?(header) }
         path = headers[header]
         body = File.read(path)
         headers['Content-Length'] = body.length.to_s
      end
      [status, headers, body]
   end
end


Camping::S << %q{
   #overwrite core-code text coz CAN'T re-evaluate already included modules/methods
   module Camping
      module Helpers
         def form_(h={}, &b)
            if %w[put delete].include?(h[:method].to_s.downcase)
               transformed=h.delete(:method)
               h[:method] = 'post'
            end
            super(h) do
               input_ :type=>'hidden', :name=>:_method, :value=>transformed
               b.call
            end
         end
         def h(str)
            str.respond_to?(:to_s) && str.gsub("<", "&lt;").gsub(">", "&gt;")
         end
         def Updater(id, url)
            %{javascript:updater('#{id}', '#{url}');return false;}
         end
         alias_method :Rjax, :Updater
         def InPlaceEditor(id, url, h={:cols=>100, :rows=>5})
            script_{ "new Ajax.InPlaceEditor('#{id}', '#{url}', {cols:#{h[:cols]}, rows:#{h[:rows]}, cancelControl:'button'})"}
         end

      end
      module Base
         include Tagz.globally
         def mab(l=nil,&b)
            if l && self.respond_to?(:layout)
               self.layout &b
            else
               tagz &b
            end
         end
         def service(*a)
            #RESTful actions
            @method=@method.downcase
            if @method == 'post' && (%w[put delete].include?(input._method.to_s.downcase))
               @env['REQUEST_METHOD'] = input._method.to_s.upcase
               @method = input._method.to_s.downcase
            end
            r = catch(:halt){send(@method, *a)}
            @body ||= r
            self
         end
      end
      module Controllers
         class << self
            alias_method :old_R, :R
            def R(*routes)
               klass=old_R(*routes).send :include, Views
               klass.class_eval do
                  def post
                     #required by put, delete methods
                  end
               end
               klass
            end
         end
      end
   end
}


module Camping
   VALID_KEYS = %w[app port root adapter database DB]
   TIMEOUT   = 10_000
   class << self
      attr_accessor *VALID_KEYS
      alias_method :_old_goes_, :goes

      def goes(symbol,opts={})
         # this is your camping app
         Camping._old_goes_ symbol
         @app       = Module.const_get(symbol.to_s)
         @port      = opts[:port]  || 3301
         @root      = opts[:root]  || nil   #|| 'http://localhost' #causes error if run
         @database  = opts[:database] || nil
         instance_exec(@database) do |db|
            const_set(:DB, Sequel.sqlite(db, :timeout => TIMEOUT))
            const_get(:DB).loggers << Logger.new($stdout) if opts[:logger]
            Sequel::Model.plugin :timestamps, :force=>true, :update_on_create=>true
         end if @database
      end
      def start(opts={})
         opts[:port]  ||= port()
         opts[:root]  ||= root()

         runapp = Rack::Builder.new do
            use XSendfile
            use Rack::Static, :urls => %w[/public /images /css /js /data] , :root => 'static'
            use Rack::CommonLogger
            run Camping.app
         end

         Camping.app.create rescue nil # only if you have a .create method
         puts "#{Camping.app} is running at http://localhost:#{opts[:port]}/"

         # run the web server

         Rack::Handler::Thin.run( runapp, :Port =>(opts[:port]), :Root=>opts[:root])
      end
   end
end
