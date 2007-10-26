require "rake/rdoctask"
# require "rake/testtask"
require "rake/gempackagetask"

require "rubygems"

dir     = File.dirname(__FILE__)
lib     = File.join(dir, "lib", "scout.rb")
version = File.read(lib)[/^\s*VERSION\s*=\s*(['"])(\d\.\d\.\d)\1/, 2]

task :default => [:test]

# TODO: add testing
# Rake::TestTask.new do |test|
#   test.libs       << "test"
#   test.test_files = [ "test/ts_all.rb" ]
#   test.verbose    = true
# end

Rake::RDocTask.new do |rdoc|
	rdoc.main     = "README"
	rdoc.rdoc_dir = "doc/html"
	rdoc.title    = "Scout Client Documentation"
	rdoc.rdoc_files.include( "README",  "INSTALL",
	                         "TODO",    "CHANGELOG",
	                         "AUTHORS", "COPYING",
	                         "LICENSE", "lib/" )
end

desc "Upload current documentation to Scout Gem Server"
task :upload_docs => [:rdoc] do
	sh "scp -r doc/html/* " +
	   "deploy@gems.scoutapp.com:/var/www/gems/docs"
end

spec = Gem::Specification.new do |spec|
	spec.name    = "scout"
	spec.version = version

	spec.platform = Gem::Platform::RUBY
	spec.summary  = "Scout makes monitoring and reporting on your web applications as flexible and simple as possible."

  # TODO: test suite
	# spec.test_suite_file = "test/ts_all.rb"
	spec.files           = Dir.glob("{lib,test,examples}/**/*.rb").
	                           reject { |item| item.include?(".svn") } +
	                       Dir.glob("{test,examples}/**/*.csv").
	                           reject { |item| item.include?(".svn") } +
	                           ["Rakefile", "setup.rb"]
  spec.executables     = ["scout"]

	spec.has_rdoc         = true
	spec.extra_rdoc_files = %w[ AUTHORS COPYING README INSTALL TODO CHANGELOG
	                            LICENSE ]
	spec.rdoc_options     << "--title" << "Scout Client Documentation" <<
	                         "--main"  << "README"

	spec.require_path = "lib"

	spec.author            = "Highgroove Studios"
	spec.email             = "scout@highgroove.com"
	# spec.rubyforge_project = "scout"
	spec.homepage          = "http://scoutapp.com"
	spec.description       = <<END_DESC
Scout makes monitoring and reporting on your web applications as flexible and simple as possible.

Scout is a product of Highgroove Studios.
END_DESC
end

Rake::GemPackageTask.new(spec) do |pkg|
	pkg.need_zip = true
	pkg.need_tar = true
end

desc "Publish Gem to Scout Gem Server"
task :publish do
	sh "scp -r pkg/*.gem " +
	   "deploy@gems.scoutapp.com:/var/www/gems"
end
