# Copyright 2011, Dell 
# 
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at 
# 
#  http://www.apache.org/licenses/LICENSE-2.0 
# 
# Unless required by applicable law or agreed to in writing, software 
# distributed under the License is distributed on an "AS IS" BASIS, 
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
# See the License for the specific language governing permissions and 
# limitations under the License. 
# 

class PacemakerService < ServiceObject

  def initialize(thelogger)
    @bc_name = "pacemaker"
    @logger = thelogger
  end

  #if barclamp allows multiple proposals OVERRIDE
  # def self.allow_multiple_proposals?
  #   true
  # end

  def create_proposal
    @logger.debug("Pacemaker create_proposal: entering")
    base = super

    @logger.debug("Pacemaker create_proposal: exiting")
    base
  end

  def apply_role_post_chef_call(old_role, role, all_nodes)
    @logger.debug("Pacemaker apply_role_post_chef_call: entering #{all_nodes.inspect}")

    # Make sure the nodes have a link to the dashboard on them.  This
    # needs to be done via apply_role_post_chef_call rather than
    # apply_role_pre_chef_call, since the server port attribute is not
    # available until chef-client has run.
    all_nodes.each do |n|
      node = NodeObject.find_node_by_name(n)

      next unless node.role? "hawk-server"

      hawk_server_ip = node.get_network_by_type("admin")["address"]
      hawk_server_port = node["hawk"]["server"]["port"]
      url = "http://#{hawk_server_ip}:#{hawk_server_port}/"

      node.crowbar["crowbar"] = {} if node.crowbar["crowbar"].nil?
      node.crowbar["crowbar"]["links"] = {} if node.crowbar["crowbar"]["links"].nil?
      node.crowbar["crowbar"]["links"]["Pacemaker cluster web UI (Hawk)"] = url
      node.save
    end

    @logger.debug("Pacemaker apply_role_post_chef_call: leaving")
  end

  def validate_proposal_after_save proposal
    elements = proposal["deployment"]["pacemaker"]["elements"]

    # accept proposal with no allocated node -- ie, initial state
    if not elements.has_key?("pacemaker-cluster-member") and
       not elements.has_key?("hawk-server")
       return
    end

    validate_at_least_n_for_role proposal, "pacemaker-cluster-member", 1

    if elements.has_key?("hawk-server")
      @logger.debug("Pacemaker apply_role_pre_chef_call: elts #{elements.inspect}")
      members = (elements["pacemaker-cluster-member" ] || [])
      @logger.debug("cluster members: #{members}")

      elements["hawk-server"].each do |n|
        @logger.debug("checking #{n}")
        node = NodeObject.find_node_by_name(n)
        name = node.name
        name = "#{node.alias} (#{name})" if node.alias
        unless members.include? n
          validation_error "Node #{name} has the hawk-server role but not either the pacemaker-cluster-member role."        end
      end
    end

    super
  end

end

