#
# Cookbook Name:: cloudfoundry
# Recipe:: default
#
# Copyright 2011, Ari Lerner
#
# All rights reserved - Do Not Redistribute
#

require 'digest/md5'

include_recipe "apt" 
include_recipe "git"

include_recipe "cloudfoundry::users"
include_recipe "cloudfoundry::rvm"

cloudfoundry_dir = "/home/#{node[:cloudfoundry][:user][:uid]}"

directory "#{cloudfoundry_dir}" do
  owner node[:cloudfoundry][:user][:uid]
  group node[:cloudfoundry][:user][:gid]
  action :create
end

git "#{cloudfoundry_dir}/vcap" do
  user node[:cloudfoundry][:user][:uid]
  repository "https://github.com/cloudfoundry/vcap.git"
  reference "master"
  action :sync
end 

execute "run submodule update for vcap" do
  user node[:cloudfoundry][:user][:uid]
  cwd "#{cloudfoundry_dir}/vcap"
  command "git submodule update --init"
end

gem_package "vmc"

# Setup vcap
%w(curl libcurl3 bison build-essential zlib1g-dev libssl-dev libreadline5-dev libxml2 libxml2-dev 
    libxslt1.1 libxslt1-dev git-core sqlite3 libsqlite3-ruby libsqlite3-dev unzip zip rake).each do |pkg|
  package pkg do
    action :install
  end
end

directory "/var/vcap" do
  mode 0777
end
%w(sys sys/log shared services).each do |dir|
  directory "/var/vcap/#{dir}" do
    owner node[:cloudfoundry][:user][:uid]
    recursive true
    mode 0777
  end
end

gem_package "bundler"

# Install Router
include_recipe "nginx"

%w(ruby-dev libmysql-ruby libmysqlclient-dev libpq-dev postgresql-client).each do |pkg|
  package pkg do
    action :install
  end
end


# Build mysql
include_recipe "mysql::server"
%w(ruby-dev libmysql-ruby libmysqlclient-dev).each do |pkg|
  package pkg do
    action :install
  end
end
execute "set mysql pass in the mysql_node.yml" do
  cwd "#{cloudfoundry_dir}/vcap/services/mysql/config"
  command "sed -i.bkup -e \"s/pass: root/pass: #{node[:mysql][:server_root_password]}/\" mysql_node.yml"
end
gem_package "mysql"

# Setup postgres
include_recipe "postgresql"
gem_package "pg"

# Install DEA
%w(lsof psmisc librmagick-ruby python-software-properties curl java-common).each do |pkg|
  package pkg do
    action :install
  end
end

case node[:platform]
when "ubuntu","CentOS","RedHat","Fedora"
  %w(openjdk-6-jre).each do |pkg|
    package pkg do
      action :install
    end
  end
end

include_recipe "nodejs"

# Rubygems and support
%w(rack rake thin sinatra eventmachine).each do |gem_pkg|
  gem_package "#{gem_pkg}"
end

directory "/var/vcap.local" do
  recursive true
  mode 0777
end

# Secure directories
directory '/var' do
  mode 0755
end

%w(sys shared).each do |dir|
  directory dir do
    owner node[:cloudfoundry][:user][:uid]
    mode 0700
    recursive true
  end
end

directory "/var/vcap.local" do
  owner node[:cloudfoundry][:user][:uid]
  mode 0711
  recursive true
end

directory "/var/vcap.local/apps" do
  mode 0711
  recursive true
end

include_recipe "redis"

%w(erlang rabbitmq mongodb::source).each do |recipe|
  include_recipe recipe
end

# Change nginx
execute "restart_nginx" do
  command "/etc/init.d/nginx restart"
  action :nothing
end

template "/etc/nginx/nginx.conf" do
  source "simple.nginx.conf.erb"
  owner "root"
  group "root"
  mode 0400
  notifies :run, resources(:execute => "restart_nginx"), :immediately
end

# This feels like a hack... something is up with vagrant
directory "#{node[:cloudfoundry][:user][:home_dir]}/.gem" do
  owner node[:cloudfoundry][:user][:uid]
  recursive true
  mode 0755
end

execute "Install bundler to the rvm ruby 1.9.2" do
  user node[:cloudfoundry][:user][:uid]
  command  <<-CODE
    /bin/bash "/etc/profile.d/rvm.sh"
    rvm use #{node[:cloudfoundry][:rvm][:default_ruby]}@global
    gem install bundler --no-ri --no-rdoc
  CODE
  not_if "gem list | grep bundler"
end

# TODO: MAKE THIS PRETTY
Dir["#{cloudfoundry_dir}/vcap"].each do |dir|
  if File.directory?(dir)
    puts "Directory: #{dir}"
  end
end
execute "Run rake bundler:install in vcap" do
  user node[:cloudfoundry][:user][:uid]
  cwd "#{cloudfoundry_dir}/vcap"
  command "rvm use #{node[:cloudfoundry][:rvm][:default_ruby]}@global && rake bundler:install"
  environment('USER' => node[:cloudfoundry][:user][:uid], 'PWD' => "#{cloudfoundry_dir}/vcap", 'HOME' => cloudfoundry_dir)
end

# This is because we are running as a lower user (kind of a hack)
directory "/tmp/vcap-run" do
  owner node[:cloudfoundry][:user][:uid]
  group node[:cloudfoundry][:user][:gid]
  action :create
end

execute "Start cloudfoundry" do
  user node[:cloudfoundry][:user][:uid]
  cwd "#{cloudfoundry_dir}/vcap"
  command "rvm use #{node[:cloudfoundry][:rvm][:default_ruby]}@global && bin/vcap start"
end