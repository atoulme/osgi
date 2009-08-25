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
    def writeFeatureXml(plugins, args)
      x = Builder::XmlMarkup.new(:target => out = "", :indent => 1)
      x.instruct!
      feature_properties = {"id" => args[:id], "label" => "%feature.name", "version" => args[:version], "provider-name" => "%provider.name"}
      feature_properties.merge!("plugin" => args[:branding_plugin]) if args[:branding_plugin]
      feature_properties.merge!("plugin" => args[:image]) if args[:image]
      x.feature(feature_properties) {
        x.description( "%description", "url" => "%changesURL")
        x.copyright(args[:copyright])
        x.license("%license", "url" => "%licenseURL")
        x.url {
          args[:update_sites].each_index {|index| x.update("label" => "%updatesite.name#{index}", "url" => args[:update_sites].at(index) )} unless args[:update_sites].nil?
          args[:discovery_sites].each_index {|index| x.discovery("label" => "%discoverysite.name#{index}", "url" => args[:discovery_sites].at(index) )} unless args[:discovery_sites].nil?
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
    def writeFeatureProperties(args)
      properties = <<-PROPERTIES
# Built by Buildr4OSGi

feature.name=#{args[:label]}
provider.name=#{args[:provider]}
changesURL=#{args[:changesURL]}
description=#{args[:description]}
licenseURL=#{args[:licenseURL]}
license=#{args[:license]}

PROPERTIES
      args[:update_sites].each_index {|index| "updatesite.name#{index}=#{args[:update_sites].at(index)}\n" } unless args[:update_sites].nil?
      args[:discovery_sites].each_index {|index| "discoverysite.name#{index}=#{args[:discovery_sites].at(index)}\n"} unless args[:discovery_sites].nil?
      properties
    end

    module_function :writeFeatureXml, :writeFeatureProperties
  end

  class FeatureTask < ::Buildr::Packaging::Java::JarTask
    include FeatureWriter
    attr_accessor :plugins
    
    attr_accessor :label
    attr_accessor :copyright
    attr_accessor :provider
    attr_accessor :description
    attr_accessor :changesURL
    attr_accessor :license
    attr_accessor :licenseURL
    attr_accessor :branding_plugin

    attr_accessor :update_sites
    attr_accessor :discovery_sites

    def initialize(*args) #:nodoc:
      super
      @plugins = []
      @update_sites = []
      @discovery_sites = []

    end
    
    def generateFeature(project)
      mkpath File.join(project.base_dir, 'target')
      resolved_plugins = {}
      unless @plugins.nil? || @plugins.empty?
        Buildr.artifacts(plugins).flatten.each do |plugin|
          resolved_plugins[adaptPlugin(plugin)] = plugin
        end
      end
      File.open(File.join(project.base_dir, 'target', 'feature.xml'), 'w') do |f|
        f.write(writeFeatureXml(resolved_plugins.keys, :id => project.id, :version => project.version, 
        :branding_plugin => branding_plugin, 
        :copyright => copyright, 
        :update_sites => update_sites.collect {|site| site[:url]}, 
        :discovery_sites => discovery_sites.collect {|site| site[:url]}))
      end
      File.open(File.join(project.base_dir, 'target', 'feature.properties'), 'w') do |f|
        f.write(writeFeatureProperties(:label => label, 
        :provider => provider, 
        :changesURL => changesURL,
        :description => description,
        :licenseURL => licenseURL, 
        :license => license, 
        :update_sites => update_sites.collect {|site| site[:name]}, 
        :discovery_sites => discovery_sites.collect {|site| site[:name]}))
      end
      path("eclipse/features/#{project.id}_#{project.version}").include File.join(project.base_dir, 'target/feature.xml'), 
        File.join(project.base_dir, 'target/feature.properties')
      resolved_plugins.each_pair do |info, plugin|  
        include(plugin, :as => "eclipse/plugins/#{info[:id]}_#{info[:version]}.jar")
      end
    end
    
    protected
    
    def adaptPlugin(plugin)
      
      plugin = Buildr::artifact(plugin) if plugin.is_a?(String)
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