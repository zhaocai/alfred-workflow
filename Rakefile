# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :bundler
Hoe.plugin :test

Hoe.plugin :git
Hoe.plugin :rubygems
Hoe.plugin :version

Hoe.spec 'alfred-workflow' do

  developer('Zhao Cai', 'caizhaoff@gmail.com')

  testlib = :minitest
  extra_deps << ['plist', '~> 3.1.0']
  extra_deps << ['logging', '~> 1.8.0']
end

# vim: syntax=ruby
