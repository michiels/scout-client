require "rake/rdoctask"
require "rake/testtask"
require "rake/gempackagetask"
require "rake/contrib/rubyforgepublisher"
require "net/ssh"

require "rubygems"
require "rubyforge"

dir = File.dirname(__FILE__)
lib = File.join(dir, "lib", "scout.rb")
version = File.read(lib)[/^\s*VERSION\s*=\s*(['"])(\d\.\d\.\d)\1/, 2]
history = File.read("CHANGELOG").split(/^(===.*)/)
changes ||= history[0..2].join.strip

need_tar = true
need_zip = true

task :default => [:test]

Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = [ "test/scout_test.rb" ]
  test.verbose = true
end

Rake::RDocTask.new do |rdoc|
  rdoc.main = "README"
  rdoc.rdoc_dir = "doc/html"
  rdoc.title = "Scout Client Documentation"
  rdoc.rdoc_files.include( "README",  "INSTALL",
                           "TODO",    "CHANGELOG",
                           "AUTHORS", "COPYING",
                           "LICENSE", "lib/" )
end

spec = Gem::Specification.new do |spec|
  spec.name = "scout"
  spec.version = version

  spec.platform = Gem::Platform::RUBY
  spec.summary = "Scout makes monitoring and reporting on your web applications as flexible and simple as possible."

  # TODO: test suite
  # spec.test_suite_file = "test/ts_all.rb"
  spec.files = Dir.glob("{bin,lib}/**/*.rb") +
          Dir.glob("{data,vendor}/**/*") +
          %w[Rakefile]
  spec.executables = ["scout"]

  spec.has_rdoc = true
  spec.extra_rdoc_files = %w[ AUTHORS COPYING README INSTALL TODO CHANGELOG
	                            LICENSE ]
  spec.rdoc_options << "--title" << "Scout Client Documentation" <<
          "--main" << "README"

  spec.require_path = "lib"

  spec.add_dependency "elif"

  spec.author = "Highgroove Studios"
  spec.email = "scout@highgroove.com"
  spec.rubyforge_project = "scout"
  spec.homepage = "http://scoutapp.com"
  spec.description = <<END_DESC
Scout makes monitoring and reporting on your web applications as flexible and simple as possible.

Scout is a product of Highgroove Studios.
END_DESC
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = need_tar
  pkg.need_tar = need_zip
end

desc "Publishes to Scout Gem Server and Rubyforge"
task :publish => [:package, :publish_rubyforge]

desc "Publishes Gem to Rubyforge"
task :publish_rubyforge => [:package] do
  puts "Publishing on RubyForge"
  forge = RubyForge.new
  forge.configure
  puts "Logging in"
  forge.login

  release = forge.userconfig
  release["release_changes"] = File.read(File.join(dir, "CHANGELOG"))
  release["preformatted"] = true

  package = "pkg/#{spec.name}-#{version}"
  files = %W[#{package}.tgz #{package}.zip #{package}.gem].compact

  puts "Releasing #{spec.name}-#{version}"
  forge.add_release(spec.rubyforge_project, spec.name, version, *files)
end

desc "Upload current documentation to Scout Gem Server and RubyForge"
task :upload_docs => [:rdoc] do
  sh "scp -r doc/html/* " +
          "deploy@gems.scoutapp.com:/var/www/gems/docs"

  config = YAML.load(File.read(File.expand_path("~/.rubyforge/user-config.yml")))
  host = "#{config["username"]}@rubyforge.org"

  remote_dir = "/var/www/gforge-projects/#{spec.rubyforge_project}"
  local_dir = 'doc/html'

  sh %{rsync -av --delete #{local_dir}/ #{host}:#{remote_dir}}
end

desc "Add new files to Subersion"
task :svn_add do
  system "svn status | grep '^\?' | sed -e 's/? *//' | sed -e 's/ /\ /g' | xargs svn add"
end
