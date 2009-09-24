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

module Buildr4OSGi #:nodoc:
  
  # A module dedicated to building jars into OSGi bundles to serve as libraries.
  #
  module BuildLibraries
    
    # A small extension contributed to projects that are library projects
    # so we can walk the libraries we pass to them.
    #
    module LibraryProject
      
      #
      # Walks the libraries passed in parameter, passing each library to the block.
      #
      def walk_libs(lib, &block)
        if (lib.is_a?(Struct) || lib.is_a?(Array))
          lib.each {|structdep|
            walk_libs(structdep, &block)
          }
          return
        end
        lib_artifact = case 
        when lib.is_a?(Artifact)  then lib
        when lib.is_a?(String) then Buildr::artifact(lib)
        else
          raise "Don't know how to interpret lib #{lib}"
        end
        block.call(lib_artifact)
      end
      
      def package_as_library_project(file_name)
        ::OSGi::BundleTask.define_task(file_name).tap do |plugin|

          manifest_location = File.join(project.base_dir, "META-INF", "MANIFEST.MF")
          manifest = project.manifest
          if File.exists?(manifest_location)
            read_m = ::Buildr::Packaging::Java::Manifest.parse(File.read(manifest_location)).main
            manifest = project.manifest.merge(read_m)
          end
          manifest["Bundle-Version"] = project.version # the version of the bundle packaged is ALWAYS the version of the project.
          manifest["Bundle-SymbolicName"] ||= project.id # if it was resetted to nil, we force the id to be added back.

          plugin.with :manifest=> manifest, :meta_inf=>meta_inf
          plugin.with [compile.target, resources.target].compact
        end

      end

      def package_as_library_project_spec(spec) #:nodoc:
        spec.merge(:type=>:jar)
      end
    end

    # Monkey-patching the artifact so that it warns instead of failing
    # when it cannot download the source
    module SkipSourceDownload
      def fail_download(remote_uris)
        warn "Failed to download the sources #{to_spec}, tried the following repositories:\n#{remote_uris.join("\n")}"
      end
    end
    
    #
    # Returns the main section of the manifest of the bundle.
    #
    def manifest(lib)
      artifact = Buildr.artifact(lib)
      artifact.invoke # download it if needed.
      
      m = nil
      Zip::ZipFile.open(artifact.to_s) do |zip|
        raise "No manifest contained in #{lib}" if zip.find_entry("META-INF/MANIFEST.MF").nil?
        m = zip.read("META-INF/MANIFEST.MF")
      end
      manifest = ::Buildr::Packaging::Java::Manifest.new(m)
      manifest.main
    end
  end
  
  module LibraryProjectExtension
    include Extension
    
    #
    #
    # Defines a project as the merge of the dependencies.
    # group: the group of the project to define
    # name: the name of the project to define
    # version: the version of the project to define
    #
    def library_project(dependencies, group, name, version, options = {:exclude => ["META-INF/MANIFEST.MF"], :include => [], :manifest => {}})
      options[:manifest] ||= {} 
      deps_as_str = []
      # We create an object and we extend with the module so we can get access to the walk_libs method.
      walker = Object.new 
      walker.extend Buildr4OSGi::BuildLibraries::LibraryProject
      walker.walk_libs(dependencies) {|lib|
        deps_as_str << lib.to_spec
      }
      deps_as_str = deps_as_str.flatten.inspect
      exclusion = options[:exclude].collect {|exclusion| ".exclude(#{exclusion.inspect})"}.join if options[:exclude]
      inclusion = options[:include].collect {|inclusion| ".include(#{inclusion.inspect})"}.join if options[:include]
      exclusion ||= ""
      inclusion ||= ""
      eval %{
        desc "#{name}"
        define "#{name}" do
          project.extend Buildr4OSGi::LibraryProject
          #{"project.version = \"#{version}\"" if version}
          #{"project.group = \"#{group}\"" if group}

          package(:library_project).tap {|jar|
            jar.enhance {|task|
              walk_libs(#{deps_as_str}) {|lib|
                lib.invoke # make sure the artifact is present.
                task.merge(lib)#{exclusion}#{inclusion}
              }
            }
            entries = []
            names = []
            walk_libs(#{deps_as_str}) {|lib|
              names << lib.to_spec 
              lib.invoke # make sure the artifact is present.
              Zip::ZipFile.foreach(lib.to_s) {|entry| entries << entry.name.sub(/(.*)\\/.*.class$/, '\\1').gsub(/\\//, '.') if /.*\\.class$/.match(entry.name)}
            }
            lib_manifest = { 
              "Bundle-Version" => "#{version}",
              "Bundle-SymbolicName" => project.name,
              "Bundle-Name" => names.join(", "),
              "Bundle-Vendor" => "Intalio, Inc."
            }
            lib_manifest["Export-Package"] = entries.uniq.sort.join(",") unless entries.empty?
            
            jar.with :manifest => lib_manifest.merge(#{options[:manifest].inspect})
            
            
          }
          package(:sources).tap do |task|
            task.enhance do
              walk_libs(#{deps_as_str}) {|lib|
                lib_src = Buildr::artifact(lib.to_hash.merge(:classifier => "sources"))
                lib_src.extend Buildr4OSGi::SkipSourceDownload
                lib_src.invoke # make sure the artifact is present.
                
                task.merge(lib_src)#{exclusion}#{inclusion} if File.exist?(lib_src.to_s)
              }
            end
          end
        end
      }
    end
  end
end

module Buildr4OSGi
  include Buildr4OSGi::BuildLibraries
  include Buildr4OSGi::LibraryProjectExtension
end

class Buildr::Project
  include Buildr4OSGi::LibraryProjectExtension
end

