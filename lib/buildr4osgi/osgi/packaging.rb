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
  
  #monkey patch the Unzip task to support unzipping tgz
  #TODO: find out how to apply the patterns (include/exclude) and move this to buildr eventually
  class Buildr::Unzip
    def extract
      # If no paths specified, then no include/exclude patterns
      # specified. Nothing will happen unless we include all files.
      if @paths.empty?
        @paths[nil] = FromPath.new(self, nil)
      end

      # Otherwise, empty unzip creates target as a file when touching.
      mkpath target.to_s
      zip_file_path = zip_file.to_s
      if zip_file_path.match /\.[t?]gz$/ or zip_file_path.match /\.tar\.gz$/
        #un-tar.gz
        @paths.each do |path, patterns|
          patterns.include = ['*'] if patterns.include.nil?
          patterns.exclude = [] if patterns.exclude.nil?
        end
        Zlib::GzipReader.open(zip_file_path) { |tar|
          Archive::Tar::Minitar::Input.open(tar) do |inp|
          inp.each do |entry|
            if included?(entry.full_name)
              trace "Extracting #{entry.full_name}"
              inp.extract_entry(target.to_s, entry)
            end
          end
        end
        }
      else
        Zip::ZipFile.open(zip_file.to_s) do |zip|
          entries = zip.collect
          @paths.each do |path, patterns|
            patterns.map(entries).each do |dest, entry|
              next if entry.directory?
              dest = File.expand_path(dest, target.to_s)
              trace "Extracting #{dest}"
              mkpath File.dirname(dest) rescue nil
              entry.restore_permissions = true
              entry.extract(dest) { true }
            end
          end
        end
      end
      # Let other tasks know we updated the target directory.
      touch target.to_s
    end
    
    #reads the includes/excludes and apply them to the entry_name
    def included?(entry_name)
      @paths.each do |path, patterns|
        return true if path.nil?
        if entry_name =~ /^#{path}/
          short = entry_name.sub(path, '')
          if patterns.include.any? { |pattern| File.fnmatch(pattern, entry_name) } &&
            !patterns.exclude.any? { |pattern| File.fnmatch(pattern, entry_name) }
           # trace "tar_entry.full_name " + entry_name + " is included"
            return true
          end
        end
      end
     # trace "tar_entry.full_name " + entry_name + " is excluded"
      return false
    end
    
  end

  
  #
  # The task to package a project
  # as a OSGi bundle.
  #
  class BundleTask < ::Buildr::Packaging::Java::JarTask
    include BundlePackaging
    # Artifacts to include under /lib.
    attr_accessor :libs
    
    # Calls to this method will make the bundle use
    # the bundle manifest version if defined.
    # An exception will be raised if no manifest file is present or no Bundle-Version is present in it.
    #
    #
    def use_bundle_version
      manifest_location = File.join(@project.base_dir, "META-INF", "MANIFEST.MF")
      if File.exists?(manifest_location)
        read_m = ::Buildr::Packaging::Java::Manifest.parse(File.read(manifest_location)).main
        raise "Cannot use use_bundle_version if no Bundle-Version header is specified in the manifest" if read_m["Bundle-Version"].nil?
        manifest["Bundle-Version"] = read_m["Bundle-Version"]
      else
        raise "Cannot use use_bundle_version if no manifest is present in the project"
      end
      process_qualifier
    end
    
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
    
    def process_qualifier
      if manifest["Bundle-Version"].match /\.qualifier$/
        manifest["Bundle-Version"] = "#{$~.pre_match}.#{Time.now.strftime("%y%m%d%H%M%S")}"
      end
    end
    
    private
    
    def associate_with(project)
      @project = project
    end
    
  end
  
  module ActAsOSGiBundle
    include Extension
    
    protected
    
    # returns true if the project defines at least one bundle packaging.
    # We keep this method protected and we will call it using send.
    def is_packaging_osgi_bundle()
      packages.each {|package| return true if package.is_a?(::OSGi::BundlePackaging)}
      return false
    end    
    
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
        p_r.exclude("src/**").exclude("*src*").exclude("*src/**").exclude("build.properties")
        p_r.exclude("bin").exclude("bin/**")
        p_r.exclude("target/**").exclude("target")
        
        
        properties = ResourcesTask.define_task
        properties.send :associate_with, project, :main
        properties.from(File.join(project.base_dir, project.layout[:source, :main, :java])).
          exclude("**/.*").exclude("**/*.java") if File.exists? File.join(project.base_dir, project.layout[:source, :main, :java])
        
        manifest_location = File.join(project.base_dir, "META-INF", "MANIFEST.MF")
        manifest = project.manifest
        if File.exists?(manifest_location)
          read_m = ::Buildr::Packaging::Java::Manifest.parse(File.read(manifest_location)).main
          manifest = project.manifest.merge(read_m)
        end
        
        manifest["Bundle-Version"] = project.version # the version of the bundle packaged is ALWAYS the version of the project.
        # You can override it later with use_bundle_version
        
        
        manifest["Bundle-SymbolicName"] ||= project.name.split(":").last # if it was resetted to nil, we force the id to be added back.
        
        plugin.with :manifest=> manifest, :meta_inf=>meta_inf
        plugin.with [compile.target, resources.target, p_r.target, properties.target].compact
        plugin.process_qualifier
      end
      task.send :associate_with, self
      task
    end
    
    def package_as_bundle_spec(spec) #:nodoc:
      spec.merge(:type=>:jar, :id => name.split(":").last)
    end
    
    before_define do |project|
      project.manifest["Bundle-SymbolicName"] = project.name.split(":").last
      project.manifest["Bundle-Name"] = project.comment || project.name
      project.manifest["Bundle-Version"] = project.version
    end
  end
  
  module BundleProjects #:nodoc
    
    # Returns the projects
    # that define an OSGi bundle packaging.
    #
    def bundle_projects
      
      Buildr.projects.flatten.select {|project|
        project.send :is_packaging_osgi_bundle
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