#
# Cookbook Name:: rsdns
# Provider:: record
#
# Copyright 2013, Rackspace
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

include Rackspace::DNS
require 'dnsruby'

action :create do
  zone = rsdns.zones.find{|z| z.domain == new_resource.domain}
  if zone
    record = zone.records.find{|r| r.name == new_resource.name && r.type == new_resource.type}
    if record.nil?
      Chef::Log.info("Creating new record #{new_resource.name}")
      zone.records.create(:name => new_resource.name,
                          :value => new_resource.value,
                          :type => new_resource.type,
                          :ttl => new_resource.ttl,
                          :priority => new_resource.priority)
      new_resource.updated_by_last_action(true)
    else
      # Check against public DNS to reduce the amount of API traffic
      res = Dnsruby::DNS.open
      begin
        current = res.getresource(new_resource.name, new_resource.type)
        if new_resource.type == 'A'
          if new_resource.value != current.address.to_s
            diff = true
          end
        elsif new_resource.type == 'CNAME'
          if new_resource.value != current.cname.to_s
            diff = true
          end
        else
          # Being lazy for other record types and always updating
          diff = true
        end
        
        if diff
          Chef::Log.info("Updating record #{new_resource.name}")
          record.name = new_resource.name
          record.value = new_resource.value
          record.type = new_resource.type
          record.ttl = new_resource.ttl
          record.priority = new_resource.priority
          record.save
          new_resource.updated_by_last_action(true)
        else
          Chef::Log.info("No update to record #{new_resource.name} necessary")
          new_resource.updated_by_last_action(false)
        end
      rescue
        Chef::Log.warn("Resolution of #{new_resource.name} failed. Not making any changes at this time.")
        new_resource.updated_by_last_action(false)
      end
    end
  else
    Chef::Log.warn("Domain #{new_resource.domain} for #{new_resource.name} does not exist")
    new_resource.updated_by_last_action(false)
  end
end

action :delete do
  zone = rsdns.zones.find{|z| z.domain == new_resource.domain}
  if zone
    record = zone.records.find{|r| r.name == new_resource.name && r.type == new_resource.type}
    if record
      Chef::Log.info("Removing record #{new_resource.name}")
      record.destory
    else
      Chef::Log.info("Record #{new_resource.name} does not exist")
      new_resource.updated_by_last_action(false)
    end
  else
    Chef::Log.warn("Domain #{new_resource.domain} for #{new_resource.name} does not exist")
    new_resource.updated_by_last_action(false)
  end
end
