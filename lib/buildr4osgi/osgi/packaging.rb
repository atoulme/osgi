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
  
  class RootFilter < Buildr::Filter
    
    def pattern_match(file, pattern)
      case
      when pattern.is_a?(Regexp)
        return file.match(pattern)
      when pattern.is_a?(String)
        return File.fnmatch(pattern, file)
      when pattern.is_a?(Proc)
        return pattern.call(file)
      else
        raise "Cannot interpret pattern #{pattern}"
      end
    end
    # :call-seq:
    #    run => boolean
    #
    # Runs the filter.
    def run
      sources.each { |source| raise "Source directory #{source} doesn't exist" unless File.exist?(source.to_s) }
      raise 'No target directory specified, where am I going to copy the files to?' if target.nil?

      copy_map = sources.flatten.map(&:to_s).inject({}) do |map, source|
        files = Util.recursive_with_dot_files(source).
          map { |file| Util.relative_path(file, source) }.
          select { |file| @include.empty? || @include.any? { |pattern| pattern_match(file, pattern) } }.
          reject { |file| @exclude.any? { |pattern| pattern_match(file, pattern) } }
        files.each do |file|
          src, dest = File.expand_path(file, source), File.expand_path(file, target.to_s)
          map[file] = src if !File.exist?(dest) || File.stat(src).mtime >= File.stat(dest).mtime
        end
        map
      end
        
      mkpath target.to_s
      return false if copy_map.empty?

      copy_map.each do |path, source|
        dest = File.expand_path(path, target.to_s)
        if File.directory?(source)
          mkpath dest
        else
          mkpath File.dirname(dest)
          if @mapper.mapper_type
            mapped = @mapper.transform(File.open(source, 'rb') { |file| file.read }, path)
            File.open(dest, 'wb') { |file| file.write mapped }
          else # no mapping
            cp source, dest
            File.chmod(0664, dest)
          end
        end
      end
      touch target.to_s
      true
    end
    
  end
  
  # A copy/paste of the ResourcesTask specifically modified for the job
  # of including resources located at the root of the project.
  #
  class RootResourcesTask < Buildr::ResourcesTask

    def initialize(*args) #:nodoc:
      super
      @filter = RootFilter.new
      @filter.using Buildr.settings.profile['filter'] if Hash === Buildr.settings.profile['filter']
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
        p_r = RootResourcesTask.define_task(:resources_root)
        p_r.send :associate_with, self, :root
        p_r.filter.from(base_dir).exclude(/^\..*/).exclude("*.jar").exclude("*.java").exclude("build.properties")
        p_r.exclude(lambda {|file|
          binaries_base_folder = project.compile.target.to_s.match(Regexp.escape(project.base_dir + File::SEPARATOR)) ? $~.post_match : project.compile.target.to_s
          file.match(Regexp.new(Regexp.escape binaries_base_folder)) || project.compile.sources.detect {|src_folder|
            relative_folder = src_folder.match(Regexp.escape(project.base_dir)) ? $~.post_match : src_folder
            true if file.match(Regexp.new(Regexp.escape(relative_folder.scan(/\w+/).first)))
          }
        })
        p_r.filter.exclude(/target/)
        
        properties = ResourcesTask.define_task(:resources_src)
        properties.send :associate_with, self, :resources_src
        
        unless compile.nil?
          compile.sources.each {|src_folder|
            properties.from(src_folder).exclude(".*").exclude("*.java")
          }
        end
        
        manifest_location = File.join(project.base_dir, "META-INF", "MANIFEST.MF")
        manifest = self.manifest
        if File.exists?(manifest_location)
          read_m = ::Buildr::Packaging::Java::Manifest.parse(File.read(manifest_location)).main
          manifest = self.manifest.merge(read_m)
        end
        
        manifest["Bundle-Version"] = self.version # the version of the bundle packaged is ALWAYS the version of the project.
        # You can override it later with use_bundle_version
        
        
        manifest["Bundle-SymbolicName"] ||= self.name.split(":").last # if it was resetted to nil, we force the id to be added back.
        
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