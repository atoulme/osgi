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

  OSGI_GROUP_ID = "osgi"
  
  # :nodoc:
  # Module extending projects
  # to find which matches criterias used
  # to find bundles.
  #
  module BundleProjectMatcher
    
    # Find if the project matches a specific set of criteria passed as parameter
    # The criteria are tested against the manifest of the project, using its bundle packages manifest options and the MANIFEST.MF master file.
    #
    # Returns true if at least one of the packages defined by this project match the criteria.
    #
    def matches(criteria = {:name => "", :version => "", :exports_package => "", :fragment_for => ""})
      if File.exists?(File.join(base_dir, "META-INF", "MANIFEST.MF"))
        manifest = ::Buildr::Packaging::Java::Manifest.new(File.join(base_dir, "META-INF", "MANIFEST.MF")).main
      end
      manifest ||= {}
      project.packages.select {|package| package.is_a? ::OSGi::BundlePackaging}.each {|p|
        package_manifest = manifest.dup
        package_manifest.merge!(p.manifest) if p.manifest
        if criteria[:exports_package]
          if criteria[:version]
            matchdata = package_manifest[Bundle::B_EXPORT_PKG].match(/#{Regexp.escape(criteria[:exports_package])};version="(.*)"/) unless package_manifest[Bundle::B_EXPORT_PKG].nil?
            return false unless matchdata
            exported_package_version = matchdata[1] 
            if criteria[:version].is_a? VersionRange
              return criteria[:version].in_range(exported_package_version)
            else
              return criteria[:version] == exported_package_version
            end
          else
            return false if package_manifest[Bundle::B_EXPORT_PKG].nil?
            result = !package_manifest[Bundle::B_EXPORT_PKG].match(/#{Regexp.escape(criteria[:exports_package])}[;|,]/).nil?
            result ||= !package_manifest[Bundle::B_EXPORT_PKG].match(/#{Regexp.escape(criteria[:exports_package])}$/).nil?
            return result
          end
        elsif (package_manifest[Bundle::B_NAME] == criteria[:name] || id == criteria[:name])
          
          if criteria[:version]
            if criteria[:version].is_a?(VersionRange)
              return criteria[:version].in_range(version)
            else
              return criteria[:version] == version
            end 
          else
            # depending just on the name, returning true then.
            return true
          end
        end
      }
      return false
    end
    
  end

  # A bundle is an OSGi artifact represented by a jar file or a folder.
  # It contains a manifest file with specific OSGi headers.
  #
  class Bundle
    include Buildr::ActsAsArtifact

    #Keys used in the MANIFEST.MF file
    B_NAME = "Bundle-SymbolicName"
    B_REQUIRE = "Require-Bundle"
    B_IMPORT_PKG = "Import-Package"
    B_EXPORT_PKG = "Export-Package"
    B_FRAGMENT_HOST = "Fragment-Host"
    B_VERSION = "Bundle-Version"
    B_DEP_VERSION = "bundle-version"
    B_RESOLUTION = "resolution"
    B_LAZY_START = "Bundle-ActivationPolicy"
    B_OLD_LAZY_START = "Eclipse-LazyStart"
    
    # Creates itself by loading from the manifest file passed to it as a hash
    # Finds the name and version, and populates a list of dependencies.
    def self.fromManifest(manifest, jarFile) 
      if manifest.first[B_NAME].nil?
        warn "Could not find the name of the bundle represented by #{jarFile}"
        return nil
      end
      
      #see http://aspsp.blogspot.com/2008/01/wheressystembundlejarfilecont.html for the system.bundle trick.
      #key.strip: sometimes there is a space between the comma and the name of the bundle.
      #Add the required bundles:
      bundles = []
      manifest.first[B_REQUIRE].each_pair {|key, value| bundles << Bundle.new(key.strip, value[B_DEP_VERSION], {:optional => value[B_RESOLUTION] == "optional"}) unless "system.bundle" == key} unless manifest.first[B_REQUIRE].nil?
      exports = []
      manifest.first[B_EXPORT_PKG].each_pair {|key, value| exports << BundlePackage.new(key.strip, value["version"])} unless manifest.first[B_EXPORT_PKG].nil?
      
      #Parse the version
      version = manifest.first[B_VERSION].nil? ? nil : manifest.first[B_VERSION].keys.first
      
      #Read the imports
      imports = []
      manifest.first[B_IMPORT_PKG].each_pair {|key, value| imports << BundlePackage.new(key.strip, value["version"], :is_export => false)} unless manifest.first[B_IMPORT_PKG].nil?
      
      #Read the imported packages
      
      bundle = Bundle.new(manifest.first[B_NAME].keys.first, version, {:file => jarFile, :bundles => bundles, :imports => imports, :exported_packages => exports})
      if !manifest.first[B_LAZY_START].nil? 
        # We look for the value of BundleActivationPolicy: lazy or nothing usually. 
        # lazy may be spelled Lazy too apparently, so we downcase the string in case.
        bundle.lazy_start = "lazy" == manifest.first[B_LAZY_START].keys.first.strip.downcase
      else
        bundle.lazy_start = "true" == manifest.first[B_OLD_LAZY_START].keys.first.strip unless manifest.first[B_OLD_LAZY_START].nil?
      end
      if (bundle.lazy_start)
        bundle.start_level = 4
      else
        bundle.start_level = 1
      end
      
      bundle.fragment = Bundle.new(manifest.first[B_FRAGMENT_HOST].keys.first.strip, 
        manifest.first[B_FRAGMENT_HOST].values.first[B_DEP_VERSION]) unless (manifest.first[B_FRAGMENT_HOST].nil?)
      return bundle
    end

    

    # Attributes of a bundle, derived from its manifest
    # The name is always the symbolic name
    # The version is either the exact version of the bundle or the range in which the bundle would be accepted.
    # The file is the location of the bundle on the disk
    # The optional tag is present on bundles resolved as dependencies, marked as optional.
    # The start level is deduced from the bundles.info file. Default is 1.
    # The lazy start is found in the bundles.info file
    # group is the artifact group used for Maven. By default it is set to OSGI_GROUP_ID.
    # fragment is a Bundle object that represents the fragment host of this bundle (which means this bundle is a fragment if this field is not null).
    # exported_packages is an array of strings representing the packages exported by the bundle.
    # imports is an array of BundlePackage objects representing the packages imported by the bundle.
    attr_accessor :name, :version, :bundles, :file, :optional, :start_level, :lazy_start, :group, :fragment, :exported_packages, :imports

    alias :id :name

    def initialize(name, version, args = {:file => nil, :bundles=>[], :imports => [], :optional => false}) #:nodoc:
      @name = name
      @version = VersionRange.parse(version) || (version.nil? ? nil : version.gsub(/\"/, ''))
      @bundles = args[:bundles] || []
      @imports = args[:imports] || []
      @exported_packages = args[:exported_packages] || []
      @file = args[:file]
      @optional = args[:optional]
      @start_level = 4
      @type = "jar" #it's always a jar, even if it is a directory: we will jar it for Maven.
      @group = OSGI_GROUP_ID
    end

    
    #
    # Resolves the matching artifacts associated with the project.
    #
    def resolve_matching_artifacts(project)
      # Collect the bundle projects, duplicate them so no changes can be applied to them
      # and extend them with the BundleProjectMatcher module
      b_projects = OSGi::BundleProjects::bundle_projects.select {|p| 
        p.extend BundleProjectMatcher ; p.matches(:name => name, :version => version)
      }
      #projects take precedence over the dependencies elsewhere, that's what happens in Eclipse
      # for example
      return b_projects unless b_projects.empty?
      return project.osgi.registry.resolved_containers.collect {|i| 
        i.find(:name => name, :version => version)
      }.flatten.compact.collect{|b| b.dup }
    end

    # Returns true if the bundle is an OSGi fragment.
    #
    def fragment?
      !fragment.nil?
    end

    def to_s #:nodoc:
       to_spec()
    end

    def to_yaml(opts = {}) #:nodoc:
      to_s.to_yaml(opts)
    end

    def <=>(other) #:nodoc:
      if other.is_a?(Bundle)
       return to_s <=> other.to_s
      else
        return to_s <=> other
      end
    end

    # Resolve a bundle from itself, by finding the appropriate bundle in the OSGi containers.
    # Returns self or the project it represents if a project is found to be self.
    #
    def resolve(project, bundles = resolve_matching_artifacts(project))
      bundle = case bundles.size
      when 0 then nil
      when 1 then bundles.first
      else
        OSGi::BundleResolvingStrategies.send(project.osgi.options.bundle_resolving_strategy, bundles)
      end
      if bundle.nil?
        warn "Could not resolve bundle for #{self.to_s}" 
        return nil
      end
      return bundle if bundle.is_a?(Buildr::Project)
      
      osgi = self.dup
      osgi.name = bundle.name
      osgi.version = bundle.version
      osgi.bundles = bundle.bundles
      osgi.file = bundle.file
      osgi.optional = bundle.optional
      osgi.start_level = bundle.start_level
      osgi.group = bundle.group

      osgi
    end

    # Finds the fragments associated with this bundle.
    #
    def fragments(project)
      project.osgi.registry.resolved_containers.collect {|i| 
        i.find_fragments(:host => name).select{|f|
          if f.fragment.version.is_a? VersionRange
            f.fragment.version.in_range(version)
          elsif f.fragment.version.nil?
            true
          else
            f.fragment.version == version 
          end
          }
        }.flatten.compact.collect{|b| b.dup }
      end
      
      def ==(other) #:nodoc:
        return false unless other.is_a?(Bundle)
        name == other.name && version == other.version    
      end

    end
  end