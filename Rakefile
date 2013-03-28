# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :bundler
Hoe.plugin :test

Hoe.plugin :git
Hoe.plugin :gemspec
Hoe.plugin :version

Hoe.spec 'alfred-workflow' do

  developer 'Zhao Cai', 'caizhaoff@gmail.com'

  license 'GPL-3'



  testlib = :minitest
  extra_deps << ['plist', '~> 3.1.0']
  extra_deps << ['logging', '~> 1.8.0']
end

desc "Bump Major Version and Commit"
task "bump:major" => ["version:bump:major"] do
  sh "git commit -am '! Bump version to #{ENV["VERSION"]}'"
end

desc "Bump Minor Version and Commit"
task "bump:minor" => ["version:bump:minor"] do
  sh "git commit -am '* Bump version to #{ENV["VERSION"]}'"
end
desc "Bump Patch Version and Commit"
task "bump:patch" => ["version:bump:patch"] do
  sh "git commit -am 'Bump version to #{ENV["VERSION"]}'"
end

# vim: syntax=ruby
