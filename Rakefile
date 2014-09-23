# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = "logmaster"
  gem.homepage = "http://github.com/snitko/logmaster"
  gem.license = "MIT"
  gem.summary = %Q{A wrapper around ruby stdlib Logger with emailing capabilities}
  gem.description = %Q{A wrapper around ruby stdlib Logger with emailing capabilities}
  gem.email = "roman.snitko@gmail.com"
  gem.authors = ["Roman Snitko"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new
