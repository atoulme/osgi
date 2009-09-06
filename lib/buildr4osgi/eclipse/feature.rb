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

module Buildr4OSGi

  module FeatureWriter

    attr_accessor :feature_id
    attr_accessor :version
    attr_accessor :label
    attr_accessor :copyright
    attr_accessor :image
    attr_accessor :provider
    attr_accessor :description
    attr_accessor :changesURL
    attr_accessor :license
    attr_accessor :licenseURL
    attr_accessor :branding_plugin

    attr_accessor :update_sites
    attr_accessor :discovery_sites
    
    # :nodoc:
    # When this module extends an object
    # the update_sites and discovery_sites are initialized as empty arrays.
    #
    def FeatureWriter.extend_object(obj)
      super(obj)
      obj.update_sites = []
      obj.discovery_sites = []
    end
    
    
    # Writes an Eclipse feature with this format:
    #<feature id="com.acme.MyFeature" label="%feature.name"
    #	 version="5.0.100" provider-name="%provider.name"
    #	 plugin="myPlugin.id">
    #
    #   <description url="%changesURL">
    #      %description
    #   </description>
    #
    #   <copyright>
    #      Copyright (C) 1999-2008, Acme Inc. All rights reserved.
    #The program(s) herein may be used and/or copied only with the
    #written permission of Acme Inc. or in accordance with the
    #terms and conditions stipulated in the agreement/contract under which
    #the program(s) have been supplied.
    #   </copyright>
    #
    #   <license url="%licenseURL">
    #      %license
    #    </license>
    #
    #   <url>
    #      <update label="%updateSiteName" url="http://www.example.com/siteupdate/" />
    #      <discovery label="%updateSiteName" url="http://www.example.com/siteupdate/" />
    #   </url>
    #
    #   <plugin id="org.thingy.eclipse" version="6.0.000" download-size="2262" install-size="0" unpack="false" />
    #   <plugin id="org.acme.lib.eclipse" version="6.0.000" download-size="329" install-size="0" unpack="false" />
    #
    #</feature>
    #
    def writeFeatureXml(plugins, externalize_strings = true)
      x = Builder::XmlMarkup.new(:target => out = "", :indent => 1)
      x.instruct!
      feature_properties = {"id" => feature_id, "label" => externalize_strings ? "%feature.name" : label, 
        "version" => version, "provider-name" => externalize_strings ? "%provider.name" : provider}
      feature_properties.merge!("plugin" => branding_plugin) if branding_plugin
      feature_properties.merge!("plugin" => image) if image
      x.feature(feature_properties) {
        x.description( "%description", "url" => externalize_strings ? "%changesURL" : changesURL)
        x.copyright(copyright)
        x.license(externalize_strings ? "%license" : license, "url" => externalize_strings ? "%licenseURL" : licenseURL)
        x.url {
          update_sites.each_index {|index| x.update("label" => externalize_strings ? "%updatesite.name#{index}" : update_sites.at(index)[:name], "url" => update_sites.at(index)[:url] )} unless update_sites.nil?
          discovery_sites.each_index {|index| x.discovery("label" => externalize_strings ? "%discoverysite.name#{index}" : discovery_sites.at(index)[:name], "url" => discovery_sites.at(index)[:url] )} unless discovery_sites.nil?
        }

        for plugin in plugins
          x.plugin("id" => plugin[:id], "version" => plugin[:version], "download-size" => plugin[:"download-size"], 
          "install-size" => plugin[:"install-size"], "unpack" => plugin[:unpack]) 
        end
      }
      out
    end

    # Writes the feature.properties file to a string and returns it
    # Uses predefined keys in properties to match the keys used in feature.xml
    #
    def writeFeatureProperties()
      properties = <<-PROPERTIES
# Built by Buildr4OSGi

feature.name=#{label}
provider.name=#{provider}
changesURL=#{changesURL}
description=#{description}
licenseURL=#{licenseURL}
license=#{license}

PROPERTIES
      update_sites.each_index {|index| "updatesite.name#{index}=#{update_sites.at(index)[:name]}\n" } unless update_sites.nil?
      discovery_sites.each_index {|index| "discoverysite.name#{index}=#{discovery_sites.at(index)[:name]}\n"} unless discovery_sites.nil?
      properties
    end
    
  end
  
  
  
  class FeatureTask < ::Buildr::Packaging::Java::JarTask
    
    attr_accessor :plugins
    
    attr_accessor :feature_xml
    attr_accessor :feature_properties

    def initialize(*args) #:nodoc:
      super
      @unjarred = {}
      @plugins = ArrayAddWithOptions.new(@unjarred)
    end
    
    def generateFeature(project)
      feature_id ||= project.id
      version ||= project.version
      
      mkpath File.join(project.base_dir, 'target')
      resolved_plugins = {}
      unless @plugins.nil? || @plugins.empty?
        plugins.flatten.each do |plugin|
          
          artifact = case 
            when plugin.is_a?(String)
              Buildr::artifact(plugin)
            when plugin.is_a?(Buildr::Project)
              Buildr::artifact(plugin.package(:plugin))
            else 
              plugin
            end
          info = adaptPlugin(artifact)
          info[:unjarred] = @unjarred[plugin]
          resolved_plugins[info] = artifact
        end
      end
      unless feature_xml
        File.open(File.join(project.base_dir, 'target', 'feature.xml'), 'w') do |f|
          f.write(writeFeatureXml(resolved_plugins.keys, feature_xml.nil? && feature_properties.nil? ))
        end
        path("eclipse/features/#{project.id}_#{project.version}").include File.join(project.base_dir, 'target/feature.xml')
      else
        path("eclipse/features/#{project.id}_#{project.version}").include feature_xml
      end
      unless feature_properties || feature_xml
        File.open(File.join(project.base_dir, 'target', 'feature.properties'), 'w') do |f|
          f.write(writeFeatureProperties())
        end
        path("eclipse/features/#{project.id}_#{project.version}").include File.join(project.base_dir, 'target/feature.properties')
      else
        path("eclipse/features/#{project.id}_#{project.version}").include feature_properties if feature_properties
      end
      
      resolved_plugins.each_pair do |info, plugin|  
        if info[:unjarred]
          merge(plugin, :path => "eclipse/plugins/#{info[:id]}_#{info[:version]}")
        else
          include(plugin, :as => "eclipse/plugins/#{info[:id]}_#{info[:version]}.jar")
        end
      end
    end
    
    protected
    
    class ArrayAddWithOptions < Array
      
      def initialize(options_hash) 
        @options_hash = options_hash
      end
      
      def add_with_options(plugin, options = {:unjarred => false})
        add(plugin)
        @options_hash[plugin] = options[:unjarred] if options[:unjarred]
      end
      
      alias :add :<<
      alias :<< :add_with_options

    end
    
    def adaptPlugin(plugin)
      name = nil
      size = nil
      version = nil
      group = nil
      if plugin.is_a? Buildr::Project
        plugin.package(:plugin).invoke #make sure it is present.
        size = File.size(plugin.package(:plugin).to_s)
        name = plugin.package(:plugin).manifest.main["Bundle-SymbolicName"]
        version = plugin.package(:plugin).manifest.main["Bundle-Version"]
        group = plugin.group   
      else
        plugin.invoke
        Zip::ZipFile.open(plugin.to_s) do |zip|
          entry = zip.find_entry("META-INF/MANIFEST.MF")
          unless entry.nil?
            manifest = Manifest.read(zip.read("META-INF/MANIFEST.MF"))
            bundle = ::OSGi::Bundle.fromManifest(manifest, plugin.to_s)
            unless bundle.nil?
              name = bundle.name
              version = bundle.version
            end
          end
        end
        group = plugin.to_hash[:group]
        size = File.size(plugin.to_s)
      end
      if (name.nil? || version.nil?)
        raise "The dependency #{plugin} is not an Eclipse plugin: make sure the headers " +
          "Bundle-SymbolicName and Bundle-Version are present in the manifest" 
      end
      if size.nil?
        warn "Could not determine the size of #{plugin}"
        size ||= 0
      end
      return {:id => name, :group => group, :version => version, 
        :"download-size" => size, :"install-size" => size, :unpack => false}
    end
  end

  # Methods added to project to package a project as a feature
  #
  module ActAsFeature
    include Extension

    protected

    def package_as_feature(file_name)
      task = FeatureTask.define_task(file_name)
      task.extend FeatureWriter
      task.tap do |feature|
        feature.with :manifest=>manifest, :meta_inf=>meta_inf
      end
      task.enhance do |feature|
        feature.generateFeature(project)
      end
    end
    
    def package_as_feature_spec(spec) #:nodoc:
      spec.merge(:type=>:jar, :classifier=>'feature')
    end
  end

end


module Buildr #:nodoc:
  class Project #:nodoc:
    include Buildr4OSGi::ActAsFeature
  end
end