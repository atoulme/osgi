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
  
  class Registry
    
    def containers=(containers)
      raise "OSGi containers are already set" if @containers
      @containers = containers
    end
    
    def containers
      unless @containers # we compute instances only once. Note that we keep this modifiable.
        @containers = [Buildr.settings.user, Buildr.settings.build].inject([]) { |repos, hash|
          repos | Array(hash['osgi'] && hash['osgi']['containers'])
        }
        if ENV['OSGi'] 
          @containers |= ENV['OSGi'].split(';')
        end
      end
      @containers
    end
    
    def resolved_containers
      unless @resolved_containers

        @resolved_containers = containers.collect { |container|
          OSGi::Container.new(container) 
        }
      end
      @resolved_containers
    end 
  end

end