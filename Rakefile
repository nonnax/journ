require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'fileutils'
include FileUtils

spec=Gem::Specification.new do |s|
  s.name     = %q{journ}
  s.version  = "0.1.4"
  s.date     = Time.now.strftime("%x")
  s.summary  = %q{Journal ala-mailing list}
  s.email    = %q{ironald@gmail.com}
  s.homepage = %q{http://www.google.com/group/object_id}
  s.description = %q{App by Ronald Evangelista *** Installation, sqlite3 or mysql backend, sequel-core only, tagz for markup speed}
  s.has_rdoc = true
  s.authors  = ["Ronald Evangelista"]
  s.files    =  %w|Rakefile CHANGELOG app.rb journ.dia| +
		Dir.glob( "*.rb")+
		Dir.glob( "app/*.rb")+
		Dir.glob( "db/*.{rb,sql,txt}")+
		Dir.glob( "lib/*.rb")+
		Dir.glob( "lib/*/*.rb")+
		Dir.glob( "static/*.*")+
		Dir.glob( "static/css/*.css")+
		Dir.glob( "static/js/*.js")+
		Dir.glob( "static/images/*.{gif,jpeg,jpg,bmp,png,ico}")
end

desc 'Create Gem Package'
Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = false
end

task :default=>[:package]

