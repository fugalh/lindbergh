Name="lindbergh"
task :default => [:doc, :test]

task :install => [:setup] do
  sh 'ruby setup.rb install'
end


desc "RDoc documentation"
task :doc => [:clean] do
  sh "rdoc -t #{Name} -m README README lib ext"
end

file '.config' do
  sh 'ruby setup.rb config'
end

task :setup => ['.config', :racc] do
  sh 'ruby setup.rb setup'
end

desc 'clean up'
task :clean do
  sh 'ruby setup.rb clean'
  sh 'rm -rf doc lib/lindbergh/parser.tab.rb'
end

task :dist do
  sh "darcs dist -d #{Name}-`cat VERSION`"
end

desc 'racc'
task :racc => ['lib/lindbergh/parser.tab.rb']
file 'lib/lindbergh/parser.tab.rb' => ['lib/lindbergh/parser.y'] do
  #sh 'cd lib/lindbergh; racc -v -g parser.y'
  #sh 'cd lib/lindbergh; racc -v parser.y'
  sh 'cd lib/lindbergh; racc parser.y'
end

desc 'rebuild database'
task :db => ['data/lindbergh.db']
# XXX why doesn't this skip when the data files haven't changed?
task ['data/lindbergh.db'] => %w{apt nav fix}.map{|f| "extra/#{f}.dat.gz"} do
  sh 'ruby -Ilib -Iext/magvar bin/lindbergh -r extra -d data/lindbergh.db'
end
  
require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs += ['ext/magvar']
end
task :test => [:setup]

# vim: filetype=ruby
