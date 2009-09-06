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

module OSGi #:nodoc:
  
  # A module dedicated to building jars into OSGi bundles to serve as libraries.
  #
  module BuildLibraries
    
    # A small extension contributed to projects that are library projects
    # so we can walk the libraries we pass to them.
    #
    module LibraryWalker
      include Extension
      
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
      module_function :walk_libs
    end

    # Monkey-patching the artifact so that it warns instead of failing
    # when it cannot download the source
    module SkipSourceDownload
      def fail_download(remote_uris)
        warn "Failed to download the sources #{to_spec}, tried the following repositories:\n#{remote_uris.join("\n")}"
      end
    end
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
      LibraryWalker::walk_libs(dependencies) {|lib|
        deps_as_str << lib.to_spec
      }
      deps_as_str = deps_as_str.flatten.inspect
      exclusion = options[:exclude].collect {|exclusion| ".exclude(#{exclusion.inspect})"}.join if options[:exclude]
      inclusion = options[:include].collect {|inclusion| ".include(#{inclusion.inspect})"}.join if options[:include]
      exclusion ||= ""
      inclusion ||= ""
      Object.class_eval %{
        desc "#{name}"
        Buildr::define "#{name}" do
          class << self ; include OSGi::BuildLibraries::LibraryWalker ; end
          project.version = "#{version}"
          project.group = "#{group}"

          package(:jar).tap {|jar|
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
            jar.with :manifest => { 
              "Export-Package" => entries.uniq.sort.join(","),
              "Bundle-Version" => "#{version}",
              "Bundle-SymbolicName" => project.name,
              "Bundle-Name" => names.join(", "),
              "Bundle-Vendor" => "Intalio, Inc."
            }.merge(#{options[:manifest].inspect})
            
            
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
end

module Buildr4OSGi
  include OSGi::BuildLibraries
end

