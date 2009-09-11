# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.

module OSGi
  
  #
  # A class to hold the registered containers. It is possible to add containers until resolved_containers is called,
  # after which it is not possible to modify the registry anymore.
  #
  class Registry
    
    # 
    # Sets the containers of the registry
    # Raises an exception if containers have been resolved already.
    #
    def containers=(containers)
      raise "Cannot set containers, containers have been resolved already" if @resolved_containers
      @containers = containers
    end
    
    #
    # Returns the containers associated with this registry.
    # The list of containers is modifiable if resolved_containers hasn't been called yet.
    #
    def containers
      unless @containers
        p "resolving"
        p Buildr.settings.user
        @containers = [Buildr.settings.user, Buildr.settings.build].inject([]) { |repos, hash|
          repos | Array(hash['osgi'] && hash['osgi']['containers'])
        }
        if ENV['OSGi'] 
          @containers |= ENV['OSGi'].split(';')
        end
      end
      @resolved_containers.nil? ? @containers : @containers.dup.freeze
    end
    
    #
    # Resolves the containers registered in this registry.
    # This is a long running operation where all the containers are parsed.
    #
    # Containers are resolved only once.
    #
    def resolved_containers
      @resolved_containers ||= containers.collect { |container| OSGi::Container.new(container) }
      @resolved_containers
    end 
  end

end