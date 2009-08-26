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

module Buildr4OSGi
  
  class PluginTask < ::Buildr::Packaging::Java::JarTask
    
    def initialize(*args) #:nodoc:
      super
      prepare do
        includeOrWarn(".", "plugin.xml")
        includeOrWarn(".", "plugin.properties")
      end
    
    end
    
    def includeOrWarn(include_path, file_name)
      if File.exists?(file_name)
        path(include_path).include(file_name)
      else
        warn("#{file_name} is missing. Please add it to your project.")
      end
    end
    
  end
  
  module ActAsEclipsePlugin
    include Extension
    
    protected
    
    def package_as_plugin(file_name)
      task = PluginTask.define_task(file_name).tap do |plugin|
        plugin.with :manifest=> manifest, :meta_inf=>meta_inf
        plugin.with [compile.target, resources.target].compact
      end
    end
    
    def package_as_plugin_spec(spec) #:nodoc:
      spec.merge(:type=>:jar)
    end
    
    before_define do |project|
      project.manifest = {"Bundle-Version" => project.version, 
                          "Bundle-SymbolicName" => project.id, 
                          "Bundle-Name" => project.comment || project.name}.merge(project.manifest)
    end
    
  end
  
end

class ::Buildr::Project
  include Buildr4OSGi::ActAsEclipsePlugin
end