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

module OSGi #:nodoc:

  # A class to represent an OSGi bundle package.
  # Created from the Import-Package or Provide-Package (Export-Package) header.
  #
  class BundlePackage
    attr_accessor :name, :version, :bundles, :imports, :is_export
    
    def initialize(name, version, args = {}) #:nodoc:
      @name= name
      @is_export = args[:is_export]
      @version = (is_export ? version.gsub(/\"/, '') : VersionRange.parse(version, true)) if version
      @bundles = args[:bundles] || []
      @imports = args[:imports] || []
    end

    #
    # Resolves the matching artifacts associated with the project.
    #
    def resolve_matching_artifacts(project)
      # Collect the bundle projects
      # and extend them with the BundleProjectMatcher module
      b_projects = BundleProjects::bundle_projects.select {|p|
        unless p == project
          p.extend BundleProjectMatcher 
          p.matches(:exports_package => name, :version => version)
        end
      }
      return b_projects unless b_projects.empty?
      
      resolved = project.osgi.registry.resolved_containers.collect {|i| i.find(:exports_package => name, :version => version)}
      resolved.flatten.compact.collect{|b| b.dup}
    end
    
    # Resolves the bundles that export this package.
    #
    def resolve(project, bundles = resolve_matching_artifacts(project))
      bundles = case bundles.size
      when 0 then []
      when 1 then bundles
      else
        bundles = OSGi::PackageResolvingStrategies.send(project.osgi.options.package_resolving_strategy, name, bundles)
      end
      warn "No bundles found exporting the package #{name}; version=#{version}" if (bundles.empty?)
      bundles
      
    end
    
    def to_s #:nodoc:
      "Package #{name}; version #{version}"
    end
    
    # We just test the name and version as we want to be able to see if an unresolved package and a resolved one represent the same
    # bundle package.
    def ==(other)
      return false unless other.is_a? BundlePackage
      eql = name == other.name
      eql |= version.nil? ? other.version.nil? : version == other.version
      eql
    end
    
    alias :eql? :==
  end
  
end