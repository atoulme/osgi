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
  
  class Registry
    include Singleton
    
    def containers
      unless @containers # we compute instances only once.
        @containers = [Buildr.settings.user, Buildr.settings.build].inject([]) { |repos, hash|
          repos | Array(hash['osgi'] && hash['osgi']['containers'])
        }
        if ENV['OSGi'] 
          @containers |= ENV['OSGi'].split(';')
        end
      end
      @containers
    end
    
    def resolved_containers
      unless @resolved_containers

        @resolved_containers = containers.collect { |container|
          OSGi::Container.new(container) 
        }
      end
      @resolved_containers
    end 
  end
  

  class DependenciesTask < Rake::Task

    attr_accessor :project

    def initialize(*args) #:nodoc:
      super

      enhance do |task|
        dependencies = {}
        project.projects.select { |subp| subp.respond_to? :manifest_dependencies }.each do |subp|
          subp_deps = subp.manifest_dependencies
          dependencies[subp.name] = subp_deps.collect {|dep| dep.to_s } unless subp_deps.empty?
        end

        if (project.respond_to? :manifest_dependencies)
          project_deps = project.manifest_dependencies
          dependencies[project.name] = project_deps.collect {|dep| dep.to_s } unless project_deps.empty?
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
          if (number == 'A')
            return bundles
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

end