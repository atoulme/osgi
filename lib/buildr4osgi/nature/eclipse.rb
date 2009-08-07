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

module Buildr
  module Nature
    module Eclipse
      include Extension

      def eclipse
        @eclipse ||= Buildr::Nature::Eclipse::Eclipse.new(self)
        @eclipse
      end

      class Eclipse

        attr_reader :options
        def initialize(project)
          @options = OptionsFromNatures.new(project)
        end
      end

      class OptionsFromNatures < Buildr::Eclipse::Options
        attr_accessor :m2_repo_var, :project #Remove when Eclipse patch in.
        
        def initialize(project)
          #super(project) uncomment when the patch for better Eclipse task is in.
          @m2_repo_var = 'M2_REPO'
          @project = project
        end

        def self.special_attr_accessor(*names)
          names.each { |name|
            module_eval %{

              def #{name}= (value)
                @#{name} = value.is_a?(Array) ? value : [value]
              end

              def #{name}
                if @#{name}.nil?
                  if (project.parent && !project.parent.eclipse.options._#{name}.nil?)
                    @#{name} = project.parent.eclipse.options._#{name}
                  else
                    @#{name} = project.applicable_natures.collect{|n| n.eclipse.#{name}}.flatten.uniq
                  end
                end
                @#{name}
              end

              protected

              def _#{name}
                @#{name}
              end
            }
          }
        end

        special_attr_accessor :natures, :builders, :classpath_containers

      end
    end
  end
end

class Buildr::Project
  include Buildr::Nature::Eclipse
end