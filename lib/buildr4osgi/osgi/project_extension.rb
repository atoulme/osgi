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
  
  class DependenciesTask < Rake::Task

    attr_accessor :project

    def initialize(*args) #:nodoc:
      super

      enhance do |task|
        dependencies = {}
        project.projects.select { |subp| subp.respond_to? :manifest_dependencies }.each do |subp|
          subp_deps = subp.manifest_dependencies.collect {|b| b.resolve(subp)}
          dependencies[subp.name] = subp_deps.collect {|dep| dep.to_s } unless subp_deps.empty?
        end

        if (project.respond_to? :manifest_dependencies)
          dependencies[project.name] = project.manifest_dependencies.collect {|b| b.resolve(project).to_s}.sort
        end
        
        Buildr::write File.join(project.base_dir, "dependencies.yml"), dependencies.to_yaml
      end
    end
  end

  module PackageResolvingStrategies
  
    def prompt(package, bundles)
      bundle = nil
      while (!bundle)
        puts "This package #{package} is exported by all the bundles present.\n" +
              "Choose a bundle amongst those presented or press A to select them all:\n" + bundles.sort! {|a, b| a.version <=> b.version }.
        collect {|b| "\t#{bundles.index(b) +1}. #{b.name} #{b.version}"}.join("\n")
        number = gets.chomp
        begin
          return bundles if (number == 'A')
          number = number.to_i
          number -= 1
          bundle = bundles[number] if number >= 0 # no negative indexing here.
        rescue Exception => e
          puts "Invalid index"
          #do nothing
        end
      end
      [bundle]
    end
    
    def all(package, bundles)
      return bundles
    end  
    
    module_function :prompt, :all
  end
  
  module BundleResolvingStrategies
    def latest(bundles)
      bundles.sort {|a, b| a.version <=> b.version}.last
    end

    def oldest(bundles)
      bundles.sort {|a, b| a.version <=> b.version}.first
    end

    def prompt(bundles)
      bundle = nil
      while (!bundle)
        puts "Choose a bundle amongst those presented:\n" + bundles.sort! {|a, b| a.version <=> b.version }.
        collect {|b| "\t#{bundles.index(b) +1}. #{b.name} #{b.version}"}.join("\n")
        number = gets.chomp
        begin
          number = number.to_i
          number -= 1
          bundle = bundles[number] if number >= 0 # no negative indexing here.
        rescue Exception => e
          puts "Invalid index"
          #do nothing
        end
      end
      bundle
    end

    module_function :latest, :oldest, :prompt
  end
  
  module ProjectExtension
    include Extension

    first_time do
      desc 'Evaluate OSGi dependencies and places them in dependencies.rb'
      Project.local_task('osgi:resolve:dependencies') { |name| "Resolving dependencies for #{name}" }
    end

    before_define do |project|
      dependencies = DependenciesTask.define_task('osgi:resolve:dependencies')
      dependencies.project = project
    end

    def dependencies(&block)
      task('osgi:resolve:dependencies').enhance &block
    end

    class OSGi

      attr_reader :options, :registry

      def initialize(project)
        if (project.parent)
          @options = project.parent.osgi.options.dup
          @registry = project.parent.osgi.registry.dup
        end
        @options ||= Options.new
        @registry ||= ::OSGi::Registry.new
      end

      class Options
        attr_accessor :package_resolving_strategy, :bundle_resolving_strategy

        def initialize
          @package_resolving_strategy = :all
          @bundle_resolving_strategy = :latest
        end

      end
    end
    
    def osgi
      @osgi ||= OSGi.new(self)
      @osgi
    end
    
    # returns an array of the dependencies of the plugin, read from the manifest.
    def manifest_dependencies()
      return [] unless File.exists?("#{base_dir}/META-INF/MANIFEST.MF")
      manifest = Manifest.read(File.read("#{base_dir}/META-INF/MANIFEST.MF"))
      bundles = []
      manifest.first[::OSGi::Bundle::B_REQUIRE].each_pair {|key, value| 
        bundle = ::OSGi::Bundle.new(key, value[::OSGi::Bundle::B_DEP_VERSION])
        bundle.optional = value[::OSGi::Bundle::B_RESOLUTION] == "optional"
        bundles << bundle
      } unless manifest.first[::OSGi::Bundle::B_REQUIRE].nil?
      bundles
    end
  end
end

module Buildr
  class Project
    include OSGi::ProjectExtension
  end
end