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

require File.join(File.dirname(__FILE__), 'execution_environment')

module OSGi
  
  OSGI_GROUP_ID = "osgi"
  
  class GroupMatcher
    include Singleton
    attr_accessor :group_matchers
    
    def initialize
      @group_matchers = []
      # Default rule for Eclipse artifacts.
      @group_matchers << Proc.new {|n| "org.eclipse" if n.match(/org\.eclipse\..*/) }
    end
    
    def group(bundle)
      return group(bundle.id) if bundle.is_a?(Bundle)
      group_matchers.reverse.each do |group|
        result = group.call(bundle)
        return result unless result.nil?
      end
      OSGI_GROUP_ID
      
    end
  end
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
        @containers = [Buildr.settings.user, Buildr.settings.build].inject([]) { |repos, hash|
          repos | Array(hash['osgi'] && hash['osgi']['containers'])
        }
        if ENV['OSGI'] && !ENV['OSGi']
          warn "The correct constant to define for the OSGi containers is named OSGi"
          ENV['OSGi'] = ENV['OSGI']
        end
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
      @resolved_containers ||= containers.collect { |container| Container.new(container) }
      @resolved_containers
    end 
  end

    # The options for the osgi.options method
    #   package_resolving_strategy:
    #     The package resolving strategy, it should be a symbol representing a module function in the OSGi::PackageResolvingStrategies module.
    #   bundle_resolving_strategy:
    #     The bundle resolving strategy, it should be a symbol representing a module function in the OSGi::BundleResolvingStrategies module.
    #   group_matchers:
    #     A set of Proc objects to match a bundle to a groupId for maven.
    #     The array is examined with the latest added Procs first.
    #     The first proc to return a non-nil answer is used, otherwise the OGSGI_GROUP_ID constant is used.
    class Options < ::OSGi::ExecutionEnvironmentConfiguration
      attr_accessor :package_resolving_strategy, :bundle_resolving_strategy

      def initialize
        super
        @package_resolving_strategy = :all
        @bundle_resolving_strategy = :latest
      end
    end
    
    # Calls to this method return true if the package name passed as argument
    # is either part of the packages of the framework given by the execution environment
    # or part of the extra packages specified by the user.
    #
    def is_framework_package?(name)
      options.current_execution_environment.packages.include?(name) || options.extra_packages.include?(name)
    end
  
  
  def options
    @options ||= Options.new
  end
  
  def registry
    @registry ||= ::OSGi::Registry.new
  end
  
end