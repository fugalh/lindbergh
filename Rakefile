Name="lindbergh"
task :default => [:test, :doc]

task :install => [:setup] do
  sh 'ruby setup.rb install'
end


desc "RDoc documentation"
task :doc do
  sh "rdoc -t #{Name} -m README README lib"
end

file '.config' do
  sh 'ruby setup.rb config'
end

task :setup => ['.config'] do
  sh 'ruby setup.rb setup'
end

desc 'clean up'
task :clean do
  sh 'ruby setup.rb clean'
  sh 'rm -rf doc'
end

task :dist do
  sh "darcs dist -d #{Name}-`cat VERSION`"
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs += ['ext/magvar']
end
task :test => [:setup]

# vim: filetype=ruby
