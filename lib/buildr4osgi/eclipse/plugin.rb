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
        include("plugin.xml")
        include("plugin.properties")
      end
    end
    
  end
  
  module ActAsEclipsePlugin
    include Extension
    
    protected
    
    def package_as_plugin(file_name)
      task = PluginTask.define_task(file_name).tap do |plugin|
        plugin.with :manifest=> {"Bundle-SymbolicName" => project.id, "Bundle-Version" => project.version }.merge(manifest), 
          :meta_inf=>meta_inf
        plugin.with [compile.target, resources.target].compact
      end
    end
    
    def package_as_plugin_spec(spec) #:nodoc:
      spec.merge(:type=>:jar)
    end
    
  end
  
end

class ::Buildr::Project
  include Buildr4OSGi::ActAsEclipsePlugin
end