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

    VARS = [:feature_id, :version, :label, :copyright, :image, :provider, :description, :changesURL, :license, :licenseURL, :branding_plugin, :update_sites, :discovery_sites]
    
    eval(VARS.collect{|field| "attr_accessor :#{field}"}.join("\n"))
    
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
    #	 plugin="myPlugin.id" image="some_icon.gif">
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
      feature_properties.merge!("image" => image) if image
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
  
  #Marker module common to all feature packaging tasks.
  #Tasks including this module are recognized internally as tasks packaging features.
  module FeaturePackaging
    
  end
  
  class FeatureTask < ::Buildr::Packaging::Java::JarTask
    include FeaturePackaging
    attr_accessor :plugins
    
    attr_accessor :feature_xml
    attr_accessor :feature_properties
    
    FeatureWriter::VARS << :plugins
    FeatureWriter::VARS << :feature_xml
    FeatureWriter::VARS << :feature_properties
    FeatureWriter::VARS << :unjarred

    def initialize(*args) #:nodoc:
      super
      @unjarred = {}
      @plugins = ArrayAddWithOptions.new(@unjarred)
      
    end
    
    def generateFeature(project)
      mkpath File.join(project.base_dir, 'target')
      resolved_plugins = create_resolved_plugins
      enhance(resolved_plugins.values)
      unless feature_xml
        File.open(File.join(project.base_dir, 'target', 'feature.xml'), 'w') do |f|
          f.write(writeFeatureXml(resolved_plugins.keys, feature_xml.nil? && feature_properties.nil? ))
        end
        path("eclipse/features/#{feature_id}_#{project.version}").include File.join(project.base_dir, 'target', 'feature.xml')
      else
        path("eclipse/features/#{feature_id}_#{project.version}").include feature_xml
      end
      unless feature_properties || feature_xml
        File.open(File.join(project.base_dir, 'target', 'feature.properties'), 'w') do |f|
          f.write(writeFeatureProperties())
        end
        path("eclipse/features/#{feature_id}_#{project.version}").include File.join(project.base_dir, 'target', 'feature.properties')
      else
        path("eclipse/features/#{feature_id}_#{project.version}").include feature_properties if feature_properties
      end
      
      resolved_plugins.each_pair do |info, plugin| 
        unless info[:manifest].nil?
          cp plugin.to_s, project.path_to("target/#{plugin.id}_#{plugin.version}.jar")
          plugin = project.path_to("target/#{plugin.id}_#{plugin.version}.jar")
          ::Buildr::Packaging::Java::Manifest.update_manifest(plugin) {|manifest|
            #applies to sources bundles only: if it was the runtime manifest, then remove it altogether:
            unless manifest.main["Bundle-SymbolicName"].nil?
              #there was a symbolic name: assume this manifest was the runtime one.
              #we don't want OSGi to confuse the runtime jar with the sources.
              #ideally we would want keep an archive of the original
              #runtime manifest as for example MANIFEST.MF.source
              manifest.main.clear
            end
            manifest.main.merge! info[:manifest]
          }
        end
        
        if info[:unjarred]
          merge(plugin, :path => "eclipse/plugins/#{info[:id]}_#{info[:version]}")
        else
          include(plugin, :as => "eclipse/plugins/#{info[:id]}_#{info[:version]}.jar")
        end
      end
    end
    
    protected
    
    def create_resolved_plugins
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
          info = adapt_plugin(artifact)
          info[:unjarred] = @unjarred[plugin][:unjarred] unless @unjarred[plugin].nil?
          resolved_plugins[info] = artifact
        end
      end
      resolved_plugins
    end
    
    def adapt_plugin(plugin)
      name = nil
      size = nil
      version = nil
      group = nil
      repackage = nil
      sourceBundle = nil
      if plugin.is_a? Buildr::Project
        size = File.size(plugin.package(:plugin).to_s)
        name = plugin.package(:plugin).manifest.main["Bundle-SymbolicName"]
        version = plugin.package(:plugin).manifest.main["Bundle-Version"]
        group = plugin.group
        sourceBundle = plugin.package(:plugin).manifest.main["Eclipse-SourceBundle"]
      else
        plugin.invoke
        if !File.exist?(plugin.to_s) and plugin.classifier.to_s == 'sources'
          #make sure the artifact was downloaded.
          #if the artifact is for the sources feature and it could not be located,
          #don't crash. should we put something in the manifest?
          return nil
        end
        Zip::ZipFile.open(plugin.to_s) do |zip|
          entry = zip.find_entry("META-INF/MANIFEST.MF")
          unless entry.nil?
            manifest = Manifest.read(zip.read("META-INF/MANIFEST.MF"))
            sourceBundle = manifest.first["Eclipse-SourceBundle"].keys.first.strip unless manifest.first["Eclipse-SourceBundle"].nil?
            if !manifest.first["Bundle-SymbolicName"].nil?
              bundle = ::OSGi::Bundle.fromManifest(manifest, plugin.to_s)
              unless bundle.nil?
                name = bundle.name
                version = bundle.version
              end
            end
          end
        end
        group = plugin.to_hash[:group]
        size = File.size(plugin.to_s)
      end
      if plugin.classifier.to_s == 'sources' and (sourceBundle.nil? || name.nil? || version.nil?)
        # Try, if possible, to get the name and the version from the original binaries then.
        runtimeArtifact = Buildr::artifact(plugin.to_hash.merge(:classifier => nil, :type => :jar))
        runtimeManifest = extraPackagedManifest(runtimeArtifact)
        manifest = ::OSGi::create_source_bundle_manifest(runtimeManifest)
        repackage = {}
        manifest.main.each {|key,value| repackage[key] = value }
        name = repackage["Bundle-SymbolicName"].split(';').first
        version = repackage["Bundle-Version"]
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
        :"download-size" => size, :"install-size" => size, :unpack => false, :manifest => repackage}
    end
    
    #returns the META-INF/MANIFEST.MF file for something that
    #is either an artifact either a the package(:jar) of a buildr project.
    def extraPackagedManifest(plugin)
      if plugin.is_a? Buildr::Project
        return plugin.package(:plugin).manifest
      else #an artifact
        plugin.invoke
        javaManifest = ::Buildr::Packaging::Java::Manifest.from_zip(plugin.to_s)
        hash = {} #need to make it a hash:
        javaManifest.main.each {|key,value| hash[key] = value }
        return hash
      end
    end
    
  end
  
  class ArrayAddWithOptions < Array

    def initialize(options_hash) 
      @options_hash = options_hash
    end

    def add_with_options(*args)
      plugin = args.shift
      options = {}
      while(!args.empty?)
        option = args.shift
        case
        when option.is_a?(Hash)
          options.merge!(option)
        when option.is_a?(Symbol)
          options.merge!({option => true})
        else
          raise "Impossible to find what this option means: #{option}"
        end
      end
      add(plugin)
      @options_hash[plugin] = options
    end

    alias :add :<<
    alias :<< :add_with_options

  end
  
  
  module SDKFeatureEnabler
    
    def create_resolved_plugins
      resolved_plugins = {}
      unless @plugins.nil? || @plugins.empty?
        plugins.flatten.each do |plugin|
          
          artifact = case 
            when plugin.is_a?(String)
              Buildr::artifact(plugin)
            when plugin.is_a?(Buildr::Project)
              Buildr::artifact(plugin.package(:sources))
            else 
              plugin
            end
          artifact = Buildr::artifact(artifact.to_hash.merge(:classifier => "sources")) if artifact.is_a?(Buildr::Artifact)
          info = adapt_plugin(artifact)
          if !info.nil? 
            info[:unjarred] = @unjarred[plugin][:unjarred] unless @unjarred[plugin].nil?
            resolved_plugins[info] = artifact
          end
        end
      end
      resolved_plugins
    end
    
    
  end

  

  # Methods added to project to package a project as a feature
  #
  module ActAsFeature
    include Extension

    protected
    
    # returns true if the project defines at least one feature packaging.
    # We keep this method protected and we will call it using send.
    def is_packaging_feature()
      packages.each {|package| return true if package.is_a?(::Buildr4OSGi::FeaturePackaging)}
      false
    end

    def package_as_feature(file_name)
      task = FeatureTask.define_task(file_name)
      task.extend FeatureWriter
      task.feature_id ||= project.id
      task.version ||= project.version
      task.enhance do |featureTask|
        featureTask.generateFeature(project)
      end
      task
    end
    
    def package_as_feature_spec(spec) #:nodoc:
      spec.merge(:type=>:zip, :id => name.split(":").last)
    end
    
    def package_as_SDK_feature(file_name) #:nodoc:
      return package_as_sources_before_SDK_feature(file_name) unless is_packaging_feature
      featurePackage = packages.select {|package| package.is_a?(::Buildr4OSGi::FeaturePackaging)}.first.dup
      sdkPackage = FeatureTask.define_task(file_name)
      sdkPackage.enhance do |featureTask|
        featureTask.generateFeature(project)
      end
      sdkPackage.extend FeatureWriter
      sdkPackage.extend SDKFeatureEnabler
      
      FeatureWriter::VARS.each do |ivar|
        value = featurePackage.instance_variable_get("@#{ivar}")
        new_value = value.clone rescue value
        sdkPackage.instance_variable_set("@#{ivar}", new_value)
      end
      sdkPackage.label += " - Sources"
      sdkPackage.description = "Sources for " + sdkPackage.description
      sdkPackage.feature_id += ".sources"
      sdkPackage
    end
    
    def package_as_SDK_feature_spec(spec) #:nodoc:
      spec = package_as_sources_spec_before_SDK_feature(spec)
      spec.merge!(:type=>:zip, :id => name.split(":").last, :classifier => "sources") if is_packaging_feature
      spec
    end
  end

end


module Buildr #:nodoc:
  class Project #:nodoc:
    include Buildr4OSGi::ActAsFeature
    
    alias :package_as_sources_before_SDK_feature :package_as_sources
    alias :package_as_sources :package_as_SDK_feature
    
    alias :package_as_sources_spec_before_SDK_feature :package_as_sources_spec
    alias :package_as_sources_spec :package_as_SDK_feature_spec
  end
end