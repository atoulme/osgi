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
  module BuildLibraries
    module LibraryWalker
      include Extension
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

    #
    #
    # Defines a project as the merge of the dependencies.
    # group: the group of the project to define
    # name: the name of the project to define
    # version: the version of the project to define (defaults on VERSION_NUMBER)
    #
    def library_project(dependencies, group, name, version = VERSION_NUMBER)
      deps_as_str = []
      LibraryWalker::walk_libs(dependencies) {|lib|
        deps_as_str << lib.to_spec
      }
      deps_as_str = deps_as_str.flatten.inspect
      Object.class_eval %{
        desc "#{name}"
        Buildr::define "#{name}" do
          class << self ; include OSGi::BuildLibraries::LibraryWalker ; end
          project.version = "#{version}"
          project.group = "#{group}"

          package(:jar).enhance {|task|
            walk_libs(#{deps_as_str}) {|lib|
            lib.invoke # make sure the artifact is present.
            task.merge(lib).exclude("META-INF/*").exclude("*.java")
            }
          }

          package(:jar).tap {|task| 
            entries = []
            names = []
            walk_libs(#{deps_as_str}) {|lib|
              names << lib.to_spec 
              lib.invoke # make sure the artifact is present.
              Zip::ZipFile.foreach(lib.to_s) {|entry| entries << entry.to_s.sub(/(.*)\\/.*\.class$/, '\1').gsub(/\\//, '.') if /.*\.class$/.match(entry.to_s)}
            }
            task.with :manifest => { "Export-Package" => entries.uniq.sort.join(","),
              "Bundle-Version" => VERSION_NUMBER,
              "Bundle-SymbolicName" => project.name,
              "Bundle-Name" => names.join(", "),
              "Bundle-Vendor" => "Intalio, Inc."
            }
          }
          sources_id = "\#\{id\}-sources-\#\{project.version\}"
          package(:zip, :file => _("target/\#\{sources_id\}.zip")).enhance do |task|
            walk_libs(#{deps_as_str}) {|lib|
              lib_src = Buildr::artifact(lib.to_hash.merge(:classifier => "sources", :type => "zip"))
              begin
                lib_src.invoke # make sure the artifact is present.
                task.merge(lib_src).exclude("META-INF/*")
              rescue Exception => e
                trace e.message
                warn "Could not find sources for \#\{lib\}"
              end
            }
          end
        end
      }
    end
  end
end

