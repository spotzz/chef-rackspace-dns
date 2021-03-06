#
# Cookbook Name:: rackspace-dns
# Recipe:: default
#
# Copyright 2015, Rackspace
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node['platform']
when 'ubuntu', 'debian'
  # Doing this because some Rackspace images can lag at bootstrap time
#  execute 'apt-get update' do
#      command 'apt-get update'
#      action :nothing
#  end.run_action(:run)
  e = execute 'apt-get update' do
      command 'apt-get update'
      action :nothing
  end
  e.run_action(:run)

  package( 'libxslt-dev' ).run_action( :install )
  package( 'libxml2-dev' ).run_action( :install )
  package( 'build-essential' ).run_action( :install )
when 'redhat', 'centos', 'fedora', 'amazon', 'scientific'
  package( 'libxslt-devel' ).run_action( :install )
  package( 'libxml2-devel' ).run_action( :install )
end

chef_gem 'nokogiri' do
  version node['rackspace_dns']['nokogiri_version']
end
chef_gem 'fog'
chef_gem 'dnsruby'

require 'fog'
require 'dnsruby'
