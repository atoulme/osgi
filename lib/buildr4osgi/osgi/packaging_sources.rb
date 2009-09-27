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
      # a jar classifier.
      def package_as_osgi_pde_sources_spec(spec) #:nodoc:
        spec.merge(:type=>:jar, :classifier=>'sources')
      end


      # package as an OSGi bundle that contains the sources
      # of the bundle. Specialized for eclipse-PDE version 3.4.0 and more recent
      # http://help.eclipse.org/ganymede/index.jsp?topic=/org.eclipse.pde.doc.user/tasks/pde_individual_source.htm
      # file_name
      def package_as_osgi_pde_sources(file_name)
        pluginManifest = package(:plugin).manifest
        #remove the properties after the sym-name such as ';singleton=true'
        bundleSymName = pluginManifest["Bundle-SymbolicName"].split(';')[0]
        bundleVersion = pluginManifest["Bundle-Version"]

        sourcesManifest = ::Buildr::Packaging::Java::Manifest.new(nil)
        sourcesManifest.main["Bundle-ManifestVersion"]="2"
        sourcesManifest.main["Eclipse-SourceBundle"]=bundleSymName+";version=\""+bundleVersion+"\";roots:=\".\""
        sourcesManifest.main["Bundle-SymbolicName"]=bundleSymName+".sources"
        sourcesManifest.main["Bundle-Name"]=pluginManifest["Bundle-Name"]+" sources"
        sourcesManifest.main["Bundle-Version"]=bundleVersion
        bundleVendor = pluginManifest["Bundle-Vendor"]
        if (bundleVendor != nil)
          sourcesManifest.main["Bundle-Vendor"]=bundleVendor
        end
        package_as_sources_old(:sources).with :manifest=>sourcesManifest
      end


      protected 
      alias :package_as_sources_old :package_as_sources
      alias :package_as_sources :package_as_osgi_pde_sources
      
      alias :package_as_sources_spec_old :package_as_sources_spec
      alias :package_as_sources_spec :package_as_osgi_pde_sources_spec




  end
end
module Buildr #:nodoc:
  class Project #:nodoc:
    include OSGi::PackagingAsSourcesExtension
  end
end
