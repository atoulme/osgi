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

# Methods added to Project for compiling, handling of resources and generating source documentation.
module OSGi
  
  module BundleCollector #:nodoc:
    
    attr_accessor :bundles, :projects, :project_dependencies
    
    # Collects the bundles associated with a project.
    # Returns them as a sorted array.
    #
    def collect(project)
      @bundles = []
      @projects = []
      project.manifest_dependencies().each {|dep| _collect(dep, project)}
    end
    
    # Collects the bundles associated with the bundle
    # 
    def _collect(bundle, project)
      if bundle.is_a?(Bundle)
        bundle = bundle.resolve(project)
        unless bundle.nil?
          if bundle.is_a?(Buildr::Project)
            @projects << bundle
          elsif !(@bundles.include? bundle)
            @bundles << bundle
            @bundles |= bundle.fragments(project)       
            (bundle.bundles + bundle.imports).each {|b|
              _collect(b, project)
            }
          end
        end
      elsif bundle.is_a?(BundlePackage)
        bundle.resolve(project).each {|b| 
          if b.is_a?(Buildr::Project)
            @projects << b
          elsif !(@bundles.include? b)
            @bundles << b
            (b.bundles + b.imports).each {|import|
              _collect(import, project)  
            }
          end
        }
      elsif bundle.is_a?(Buildr::Project)
        @projects << bundle
      end
    end
    
  end
  
  class DependenciesTask < Rake::Task #:nodoc:
    include BundleCollector
    attr_accessor :project

    def initialize(*args) #:nodoc:
      super

      enhance do |task|
        _dependencies = {}
        _projects = {}
        project.projects.each do |subp|
          collect(subp)
          _projects[subp.name] = projects.collect {|p| p.name}.uniq.sort
          _dependencies[subp.name] = bundles.sort 
        end
        
        collect(project)
        _dependencies[project.name] = bundles.sort
        _projects[project.name] = projects.collect {|p| p.name}.uniq.sort
        
        def find_root(project)
          project.parent.nil? ? project : project.parent
        end
        
        base_dir = find_root(project).base_dir
        written_dependencies = YAML.load(File.read(File.join(base_dir, "dependencies.yml"))) if File.exists? File.join(base_dir, "dependencies.yml")
        written_dependencies ||= {}
        written_dependencies.extend SortedHash
        
       
        _projects.keys.each {|p|
          written_dependencies[p] ||= {}
          written_dependencies[p].extend SortedHash
          written_dependencies[p]["dependencies"] ||= []
          written_dependencies[p]["projects"] ||= []
          written_dependencies[p]["dependencies"] |= _dependencies[p]
          written_dependencies[p]["projects"] |= _projects[p]
          written_dependencies[p]["dependencies"].sort!
          written_dependencies[p]["projects"].sort!
        }
        
        Buildr::write File.join(base_dir, "dependencies.yml"), written_dependencies.to_yaml
      end
    end
  end
  
  class InstallTask < Rake::Task #:nodoc:
    include BundleCollector
    attr_accessor :project, :local

    def initialize(*args) #:nodoc:
      super

      enhance do |task|
        dependencies = []
        project.projects.each do |subp|
          collect(subp)
          dependencies |= bundles
        end
        collect(project)
        dependencies |= bundles
        dependencies.flatten.uniq.sort.each {|bundle|
          
          begin
            if File.directory?(bundle.file)
              begin
               
                tmp = File.join(Dir::tmpdir, File.basename(bundle.file))
                rm tmp if File.exists? tmp
                base = Pathname.new(bundle.file)
                Zip::ZipFile.open(tmp, Zip::ZipFile::CREATE) {|zipfile|
                  Dir.glob("#{bundle.file}/**/**").each do |file|
                    if(file.match(/.*\.jar/)) #unpack the jars in the directory so its contents are readable by all Java compilers.
                      Zip::ZipFile.open(file) do |source|
                        source.entries.reject { |entry| entry.directory? }.each do |entry|
                          zipfile.get_output_stream(entry.name) {|output| output.write source.read(entry.name)}
                        end
                      end
                    else
                      zipfile.add(Pathname.new(file).relative_path_from(base), file)
                    end
                  end
                }
                bundle.file = tmp
                
              rescue Exception => e
                error e.message
                trace e.backtrace.join("\n")
              end
              
            end
            
            if local
              artifact = Buildr::artifact(bundle.to_s)
              installed = Buildr.repositories.locate(artifact)
              mkpath File.dirname(installed)
              Buildr::artifact(bundle.to_s).from(bundle.file).install
              info "Installed #{installed}"
            else
              Buildr::artifact(bundle.to_s).from(bundle.file).upload
              info "Uploaded #{bundle}"
            end
          rescue Exception => e
            error "Error installing the artifact #{bundle.to_s}"
            trace e.message
            trace e.backtrace.join("\n")
          end
        }
      end
    end
  end
  
  module ProjectExtension #:nodoc:
    include Extension

    first_time do
      desc 'Evaluate OSGi dependencies and places them in dependencies.yml'
      Project.local_task('osgi:resolve:dependencies') { |name| "Resolve dependencies for #{name}" }
      desc 'Installs OSGi dependencies in the Maven local repository'
      Project.local_task('osgi:install:dependencies') { |name| "Install dependencies for #{name}" }
      desc 'Installs OSGi dependencies in the Maven local repository'
      Project.local_task('osgi:upload:dependencies') { |name| "Upload dependencies for #{name}" }
      desc 'Cleans the dependencies.yml file'
      Project.local_task('osgi:clean:dependencies') {|name| "Clean dependencies for #{name}"}
    end

    before_define do |project|
      dependencies = DependenciesTask.define_task('osgi:resolve:dependencies')
      dependencies.project = project
      install = InstallTask.define_task('osgi:install:dependencies')
      install.project = project
      install.local = true
      upload = InstallTask.define_task('osgi:upload:dependencies')
      upload.project = project
      
      
      clean = Rake::Task.define_task('osgi:clean:dependencies').enhance do
        Buildr::write File.join(project.base_dir, "dependencies.yml"), 
          project.projects.inject({}) {|hash, p| hash.merge({p.name => []})}.merge({project.name => []}).to_yaml
      end
      install.project = project
    end

    #
    # 
    # Reads the dependencies from dependencies.yml
    # and returns the direct dependencies of the project, as well as its project dependencies and their own dependencies.
    # This method is used recursively, so beware of cyclic dependencies.
    #
    def dependencies(&block)
      
      deps = Dependencies.new
      deps.read(project)
      return deps.projects + deps.dependencies
    end

    class OSGi #:nodoc:

      attr_reader :options, :registry

      def initialize(project)
        if (project.parent)
          @options = project.parent.osgi.options.dup
          @registry = project.parent.osgi.registry.dup
        end
        @options ||= Options.new
        @registry ||= ::OSGi::Registry.new
      end

      # The options for the osgi.options method
      #   package_resolving_strategy:
      #     The package resolving strategy, it should be a symbol representing a module function in the OSGi::PackageResolvingStrategies module.
      #   bundle_resolving_strategy:
      #     The bundle resolving strategy, it should be a symbol representing a module function in the OSGi::BundleResolvingStrategies module.
      class Options
        attr_accessor :package_resolving_strategy, :bundle_resolving_strategy

        def initialize
          @package_resolving_strategy = :all
          @bundle_resolving_strategy = :latest
        end

      end
    end
    
    # Makes a osgi instance available to the project.
    # The osgi object may be used to access OSGi containers
    # or set options, currently the resolving strategies.
    def osgi
      @osgi ||= OSGi.new(self)
      @osgi
    end
    
    # returns an array of the dependencies of the plugin, read from the manifest.
    def manifest_dependencies()
      as_bundle = Bundle.fromProject(self)
      as_bundle.nil? ? [] : as_bundle.bundles.collect{|b| b.resolve(self)}.compact + as_bundle.imports.collect {|i| i.resolve(self)}.flatten
    end
    
  end
  
  private
  
  #
  # A class to read dependencies.yml, and get a flat array of projects and dependencies for a project.
  class Dependencies
    
    attr_accessor :dependencies, :projects
    
    def read(project)
      def find_root(project)
        project.parent.nil? ? project : project.parent
      end
      
      base_dir = find_root(project).base_dir
      @dependencies = []
      @projects = []
      @deps_yml = {}
      return unless File.exists? File.join(base_dir, "dependencies.yml")
      @deps_yml =YAML.load(File.read(File.join(base_dir, "dependencies.yml")))
      return if @deps_yml[project.name].nil? || @deps_yml[project.name]["dependencies"].nil?
      _read(project.name, false)
      @dependencies = @dependencies.flatten.compact.uniq
      return @dependencies, @projects
    end
    
    private
    
    def _read(project, add_project = true)
      @dependencies |= @deps_yml[project]["dependencies"]
      projects << Buildr::project(project) if add_project
      @deps_yml[project]["projects"].each {|p| _read(p) unless projects.include?(p)}
    end
  end
  
  # Copy/pasted from here: http://snippets.dzone.com/posts/show/5811
  # no author information though.
  module SortedHash
    
    # Replacing the to_yaml function so it'll serialize hashes sorted (by their keys)
    #
    # Original function is in /usr/lib/ruby/1.8/yaml/rubytypes.rb
    def to_yaml( opts = {} )
      YAML::quick_emit( object_id, opts ) do |out|
        out.map( taguri, to_yaml_style ) do |map|
          sort.each do |k, v|   # <-- here's my addition (the 'sort')
            map.add( k, v )
          end
        end
      end
    end
  end
end

module Buildr #:nodoc:
  class Project #:nodoc:
    include OSGi::ProjectExtension
  end
end