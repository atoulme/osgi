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
  
  #:nodoc:
  # This module is used to identify the packaging task
  # that represent a bundle packaging.
  #
  # Tasks representing bundle packaging should include this module
  # to be used by the buildr system properly.
  #
  module PackagingAsSourcesExtension #:nodoc:
    include Extension

    # Change the zip classifier for the sources produced by
    # a jar classifier unless we are packaking a feature right now.
    def package_as_sources_respec(spec) #:nodoc:
      if self.send :is_packaging_feature
         spec[:type] = :zip
         spec
        return
      end
       spec[:type] = :jar
       spec
    end

    # if the current packaging is a plugin or a bundle
    # then call package_as_osgi_bundle_pde_sources
    # if the current packaging is a feature
    # then call package_as_feature_pde_sources
    def package_as_osgi_pde_sources(file_name)
      if project.send :is_packaging_feature
         package_as_eclipse_sources_feature(file_name)
        return
      end
      if project.send :is_packaging_osgi_bundle
         package_as_eclipse_source_bundle(file_name)
        return
      end
    end


    # package as an OSGi bundle that contains the sources
    # of the bundle. Specialized for eclipse-PDE version 3.4.0 and more recent
    # http://help.eclipse.org/ganymede/index.jsp?topic=/org.eclipse.pde.doc.user/tasks/pde_individual_source.htm
    # file_name
    def package_as_eclipse_source_bundle(file_name)
      pluginManifest = package(:plugin).manifest
      sourcesManifest = create_source_bundle_manifest(pluginManifest)
      package_as_sources_old(file_name).with :manifest => sourcesManifest
    end
    
    # package the same feature than the currently packaged feature except that
    # it contains the sources of the plugins that are packaged.
    # repackages the *-sources.jar that don't have the expected Eclipse-SourceBundle entry.
    def package_as_eclipse_sources_feature(file_name)
      #TODO
    end
    
    # generate an Eclipse-SourceBundle manifest from the manifest of a runtime plugin
    # Assumes that there are no jars inside the runtime plugin.
    def create_source_bundle_manifest(pluginManifest)
      #remove the properties after the sym-name such as ';singleton=true'
      bundleSymName = pluginManifest["Bundle-SymbolicName"].split(';')[0]
      bundleVersion = pluginManifest["Bundle-Version"]
      sourcesManifest = ::Buildr::Packaging::Java::Manifest.new(nil)
      sourcesManifest.main["Bundle-ManifestVersion"]="2"
      sourcesManifest.main["Eclipse-SourceBundle"]=bundleSymName+";version=\""+bundleVersion+"\";roots:=\".\""
      sourcesManifest.main["Bundle-SymbolicName"]=bundleSymName+".sources"
      sourcesManifest.main["Bundle-Name"]=pluginManifest["Bundle-Name"]+" sources"
      sourcesManifest.main["Bundle-Version"]=bundleVersion
      sourcesManifest.main["Bundle-Vendor"] = pluginManifest["Bundle-Vendor"] unless pluginManifest["Bundle-Vendor"].nil?
      #TODO: ability to define a different license for the sources.
      sourcesManifest.main["Bundle-License"] = pluginManifest["Bundle-License"] unless pluginManifest["Bundle-License"].nil?
     return sourcesManifest
    end
    
  end
end

module Buildr #:nodoc:
  class Project #:nodoc:
    include OSGi::PackagingAsSourcesExtension
    
    protected 
    alias :package_as_sources_old :package_as_sources
    alias :package_as_sources :package_as_osgi_pde_sources
  end
end
