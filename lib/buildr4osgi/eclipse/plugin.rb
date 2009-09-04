# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.

module Buildr4OSGi
  
  class PluginTask < ::Buildr::Packaging::Java::JarTask
    
    # Artifacts to include under /lib.
    attr_accessor :libs
    
    def initialize(*args) #:nodoc:
      super
      @libs = []
      prepare do
        unless @libs.nil? || @libs.empty?
          artifacts = Buildr.artifacts(@libs)
          path('lib').include artifacts
          manifest["Bundle-Classpath"] = [".", artifacts.collect {|a| "lib/#{File.basename(a.to_s)}"}].flatten.join(",")
        end
        
      end
    end
    
  end
  
  module ActAsEclipsePlugin
    include Extension
    
    protected
    
    def package_as_plugin(file_name)
      task = PluginTask.define_task(file_name).tap do |plugin|
        p_r = ResourcesTask.define_task
        p_r.send :associate_with, project, :main
        p_r.from("#{project.base_dir}").exclude("**/.*").exclude("**/*.jar").exclude("**/*.java")
        p_r.exclude("src/**").exclude("*src").exclude("*src/**").exclude("build.properties")
        p_r.exclude("bin").exclude("bin/**")
        p_r.exclude("target/**").exclude("target")
        
        if File.exists?("META-INF/MANIFEST.MF")
          read_m = ::Buildr::Packaging::Java::Manifest.parse(File.read("META-INF/MANIFEST.MF")).main
          project.manifest = read_m.merge(project.manifest)
        end
        manifest = {"Bundle-Version" => project.version, 
                    "Bundle-SymbolicName" => project.id, 
                    "Bundle-Name" => project.comment || project.name}.merge project.manifest
        manifest["Bundle-Version"] = project.version         
        plugin.with :manifest=> manifest, :meta_inf=>meta_inf
        plugin.with [compile.target, resources.target, p_r.target].compact
      end
    end
    
    def package_as_plugin_spec(spec) #:nodoc:
      spec.merge(:type=>:jar)
    end
    
    alias :package_as_bundle :package_as_plugin
    alias :package_as_bundle_spec :package_as_plugin_spec 
    
  end
  
end

class ::Buildr::Project
  include Buildr4OSGi::ActAsEclipsePlugin
end