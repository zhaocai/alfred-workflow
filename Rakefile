# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :bundler
Hoe.plugin :gemspec
Hoe.plugin :git
Hoe.plugin :rubygems
Hoe.plugin :version

Hoe.spec 'alfred-workflow' do

  developer('Zhao Cai', 'caizhaoff@gmail.com')

  extra_deps << ['plist', '~> 3.1.0']
  extra_deps << ['logging', '~> 1.8.0']
end

desc "Bump Patch and Release"
task "release:patch" => ["version:bump:patch"] do
  sh "git commit -a -m '* Bump version to #{ENV["VERSION"]}'"
  invoke_task(:release)
end
# vim: syntax=ruby
