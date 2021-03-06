#
# Cookbook Name:: mconf-node
# Recipe:: base
# Author:: Felipe Cecagno (<felipe@mconf.org>)
# Author:: Mauricio Cruz (<brcruz@gmail.com>)
#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

Chef::Log.info("Chef Handlers will be at: #{node[:chef_handler][:handler_path]}")

remote_directory node[:chef_handler][:handler_path] do
  source 'handlers'
  owner 'root'
  group 'root'
  mode "0755"
  recursive true
#  action :nothing
#end.run_action(:create)
  action :create
end

chef_handler "NscaHandler" do
  source "#{node[:chef_handler][:handler_path]}/nsca_handler"
  supports :report => true, :exception => true
  arguments [
    :send_nsca_binary => "#{node[:nsca][:dir]}/send_nsca",
    :send_nsca_config => "#{node[:nsca][:config_dir]}/send_nsca.cfg",
    :nsca_server => node[:nsca_handler][:nsca_server],
    :service_name => node[:nsca_handler][:service_name],
    :nsca_timeout => node[:nsca][:timeout],
    :hostname => node[:nsca][:hostname]
  ]
#  action :nothing
#end.run_action(:enable)
  action :enable
end

user node[:mconf][:user] do
  action :create  
end

[ node[:mconf][:dir],
  node[:mconf][:log][:dir],
  node[:mconf][:tools][:dir] ].each do |t|
    directory t do
        owner node[:mconf][:user]
        group node[:mconf][:user]
        recursive true
        action :create
    end
end

# create the cache directory if it doesn't exist
directory Chef::Config[:file_cache_path] do
  recursive true
  action :create
end

ruby_block "save node properties" do
  block do
    node.set[:ruby][:gem_version] = `gem -v`.strip!

    `locale`.split("\n").each do |locale|
      locale_split = locale.split("=")
      if locale_split.length < 2
        next
      end
      if locale_split[1].start_with?("\"")
        locale_split[1] = locale_split[1].gsub!(/\A"|"\Z/, '')
      end
      node.set[:os_locale][locale_split[0]] = locale_split[1]
    end
    node.save unless Chef::Config[:solo]
  end
end

if tagged?("reboot")
  node.run_state['reboot'] = true
  untag("reboot")
end

