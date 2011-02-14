# from cushion
require 'fileutils'
require 'metaid'
module Camping
   module PageCaching
      def self.included(base)
         base.send(:extend, ClassMethods)
      end
      def cached?(path)
         File.exists?(path) and !File.size(path).zero?
      end

      def ext_for_mime
         case @headers['Content-Type']
         when 'application/atom+xml'
            'xml'
         else
            'html'
         end
      end

      def name_for_resource(filename)
         if filename =~ /^(.*)\.(.*)$/
            filename
         else
            "#{filename}.#{ext_for_mime}"
         end
      end

      def cached
         # allow query strings like: /blog/1?page=1&page_num=10 to become /blog/1/page/1/page_num/10
         request_uri=env['REQUEST_URI'].gsub(/[=&?]/,'/')

         if (request_uri =~ /^((.*)\/)?([^\/]*)$/)
            path = File.join(ROOT, 'cache', $1)
            file = File.join(path, ($3 == '' && $1 == '/' ? 'index.html' : name_for_resource($3)))
            unless cached?(file)
               FileUtils.mkdir_p(path)
               File.open(file, 'w') { |f| f.write yield.to_s }
               p "caching #{request_uri}..."
            end
            @headers['X-Sendfile'] = file
         end
      end

      def sweep
         p "clearing cache..."
         FileUtils.rm_rf Dir[File.join(ROOT, 'cache', '*')]
      end

      # USAGE:
      # class ControllerX < R
      #     include Camping::PageCaching
      #     def get
      #         #  blah-blah-blah
      #     end
      #     cache_method :get
      # end
      #
      module ClassMethods
         define_method :cache_method do |*meths|
            meths.each do |m|
               alias_method "_#{m}_", m
               define_method m do |*args|
                  cached do
                     send "_#{m}_", *args
                  end
               end
            end
         end
      end
   end
end
