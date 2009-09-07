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
  module BundlePackaging
    
  end
  
  #
  # The task to package a project
  # as a OSGi bundle.
  #
  class BundleTask < ::Buildr::Packaging::Java::JarTask
    include BundlePackaging
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
  
  module ActAsOSGiBundle
    include Extension
    
    protected
    
    def package_as_bundle(file_name)
      task = BundleTask.define_task(file_name).tap do |plugin|
        # Custom resource task to grab everything located at the root of the project
        # while leaving the user also specify a resources directory, in case we are in face
        # of a complex project.
        # This is a bit hacky and not fully respecting the project layout, so we might find some alternative later
        # to do the job by extending the layout object, and maybe making this resource task available as a subclass
        # of ResourcesTask.
        p_r = ResourcesTask.define_task
        p_r.send :associate_with, project, :main
        p_r.from("#{project.base_dir}").exclude("**/.*").exclude("**/*.jar").exclude("**/*.java")
        p_r.exclude("src/**").exclude("*src").exclude("*src/**").exclude("build.properties")
        p_r.exclude("bin").exclude("bin/**")
        p_r.exclude("target/**").exclude("target")
        
        manifest_location = File.join(project.base_dir, "META-INF", "MANIFEST.MF")
        if File.exists?(manifest_location)
          read_m = ::Buildr::Packaging::Java::Manifest.parse(File.read(manifest_location)).main
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
    
    def package_as_bundle_spec(spec) #:nodoc:
      spec.merge(:type=>:jar)
    end
    
  end
  
  module BundleProjects #:nodoc
    
    # Returns the projects
    # that define an OSGi bundle packaging.
    #
    def bundle_projects
      Buildr.projects.select {|project|
        !project.packages.select {|package| package.is_a? ::OSGi::BundlePackaging}.empty?
      }
    end
    
    module_function :bundle_projects
  end
  
end

class Buildr::Project
  include OSGi::ActAsOSGiBundle
end

module Buildr4OSGi
  include OSGi::BundleProjects
end