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

      attr_reader :options

      def initialize()
        @options = Options.new  
      end

      def registry
        return OSGi::Registry.instance
      end

      class Options
        attr_accessor :package_resolving_strategy, :bundle_resolving_strategy

        def initialize
          @package_resolving_strategy = :all
          @resolving_stategy = :latest
        end

      end
    end
    
    protected
    
    # returns an array of the dependencies of the plugin, read from the manifest.
    def manifest_dependencies()
      return [] unless File.exists?("#{base_dir}/META-INF/MANIFEST.MF")
      manifest = Manifest.read(File.read("#{base_dir}/META-INF/MANIFEST.MF"))
      bundles = []
      manifest.first[B_REQUIRE].each_pair {|key, value| 
        bundle = OSGi::Bundle.new(key, value[B_DEP_VERSION])
        bundle.optional = value[B_RESOLUTION] == "optional"
        bundles << bundle
      } unless manifest.first[B_REQUIRE].nil?
      bundles
    end
  end
end

module Buildr
  class Project
    include OSGi::ProjectExtension
  end
end