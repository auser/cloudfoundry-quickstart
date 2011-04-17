#
# Cookbook Name:: cloudfoundry
# Recipe:: rvm
#
# Copyright 2011, Ari Lerner
#
# All rights reserved - Do Not Redistribute
#

group 'rvm' do
  members [node[:cloudfoundry][:user][:uid]]
  append true
end

%w(coreutils autoconf curl git-core ruby bison build-essential zlib1g-dev libssl-dev libreadline5-dev).each do |pkg|
  package pkg do
    action :install
  end
end

bash "install RVM" do
  user "root"
  code "bash < <( curl -L http://rvm.beginrescueend.com/releases/rvm-install-head )"
  not_if "which rvm"
end
cookbook_file "/etc/profile.d/rvm.sh"

node[:cloudfoundry][:rvm][:rubies].each do |ruby_version|
  bash "install #{ruby_version} with RVM" do
    user "root"
    code "rvm install #{ruby_version}"
    not_if "rvm list | grep #{ruby_version}"
  end
end

bash "make #{node[:cloudfoundry][:rvm][:default_ruby]} the default ruby" do
  user "root"
  code "rvm --default #{node[:cloudfoundry][:rvm][:default_ruby]}"
  not_if "rvm list | grep #{node[:cloudfoundry][:rvm][:default_ruby]} | grep '=>'"
end

gem_package "bundler"
