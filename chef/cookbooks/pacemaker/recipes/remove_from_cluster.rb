#
# Cookbook Name:: crowbar-pacemaker
# Recipe:: default
#
# Copyright 2014, SUSE
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

# This should be executed for a node that was removed from existing cluster.

# put the node into the standby mode

ruby_block "putting node into the standby node" do
  block do
    Mixlib::ShellOut.new("crm node standby").run_command
  end
end

# remove stonith resources
stonith_resource = "stonith-#{node[:hostname]}"
pacemaker_primitive stonith_resource do
  agent "stonith:#{node[:pacemaker][:stonith][:per_node][:agent]}"
  action [:stop, :delete]
  only_if "crm configure show #{stonith_resource}"
end

# wait for services to migrate away - don't proceed if this times out!
ruby_block "check for services migration" do
  block do
    require 'timeout'
    begin
      Timeout.timeout(60) do
        resources_running = true
        while resources_running
          sleep(1)
          cmd = Mixlib::ShellOut.new("crm_mon -n1D")
          mon = cmd.run_command.stdout.split("\n")
          # The output of crm_mon -n looks like:
          #  Node d52-54-00-21-be-67: online
          #     ceilometer-api  (lsb:openstack-ceilometer-api): Started
          #  Node d52-54-00-23-5e-72: standby
          #     mongodb (lsb:mongodb):  Started
          #  Node d52-54-00-ff-3c-63: online
          # --> we are waiting until there is no service under our standby node
          mon.each_index do |i|
            line        = mon[i]
            next_line   = mon[i+1]
            if (line =~ /Node #{node.name}:/) && (next_line.nil? || next_line =~ /Node/)
              resources_running = false
            end
          end
        end
      end
    rescue Timeout::Error
      Chef::Log.fatal("resources were not migrated from #{node.name} after trying for 1 minute")
    end
  end
end

# stop and disable the corosync service
service node[:corosync][:platform][:service_name] do
  action [:disable, :stop]
end

ruby_block "wait for corosync service to finish" do
  block do
    require 'timeout'
    begin
      Timeout.timeout(120) do
        cmd = "pgrep corosync"
        #FIXME or "service #{node[:corosync][:platform][:service_name]} status"
        while ::Kernel.system(cmd)
          Chef::Log.debug("corosync still running")
          sleep(1)
        end
      end
    rescue Timeout::Error
      Chef::Log.warn("corosync wasn't stopped after trying for 2 minutes")
    end
  end
end

file "/etc/corosync/corosync.conf" do
  action :delete
end
