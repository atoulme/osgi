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

  # The nature class is extended into project natures.
  # See for example the JavaNature of the ScalaNature.
  # A nature defines an unique id amonsgt all natures.
  # 
  # These fields may be set when initializing an instance:
  # eclipse_builders
  #   Used by the Eclipse task to output in .project, a builder being an Eclipse-specific background job to build a project.
  # eclipse_natures
  #   Used by the Eclipse task to output in .classpath, 
  #   an Eclipse nature is an Eclipse-specific concept used by the framework to determine the projects features. 
  # classpath_containers
  #  Used by the Eclipse task to output in .classpath,
  #   it is a special container identified by Eclipse for compilation.
  #
  class DefaultNature

    class EclipseOptions

      def self.attr_accessor(*names)
        names.each { |name|
          module_eval %{
            attr_reader :#{name}

            def #{name}= (value)
              @#{name} = value.is_a?(Array) ?  value : [value]

            end
          }
        }
      end

      attr_accessor :natures, :builders, :classpath_containers

    end

    attr_reader :id, :eclipse

    def initialize(id)
      @id = id
      @eclipse = EclipseOptions.new
    end  

    # Returns true if the nature applies to the project
    def applies(project)
      false
    end
  end
  
  module Nature #:nodoc:

    # The natures registry
    # This class works as a singleton and contains all the available natures.
    #
    module Registry
      
      @registered_natures = Array.new
      
      # Adds a nature to the registry.
      # Raises exception if the object provided isn't a Nature 
      # or if a Nature instance is already registered with the same id.
      def add_nature(nature, before = nil)
        raise "#{nature} is not a nature!" if (!nature.is_a? DefaultNature)
        raise "A nature with the same id is already present" if (get(nature.id))
        if before.nil?
          @registered_natures << nature
        else
          @registered_natures = @registered_natures.insert(@registered_natures.index(get(before)), nature) 
        end
      end

      # Returns a nature, from its id.
      def get(nature)
        if (nature.is_a? Symbol) then
          @registered_natures.each {|n|
            return n if (n.id == nature)
          }
        elsif (nature.is_a? String) then
          @registered_natures.each {|n|
            return n if (n.id.to_s == nature)
          }
        end
        nil
      end

      # Returns all available natures
      def all()
        return @registered_natures.dup;
      end
      
      module_function :all, :get, :add_nature
    end

    module NatureExtension
      include Extension
      # Gives the natures defined on the project
      # and the ones that apply on the project.
      def applicable_natures()
        Registry.all().select {|n| (natures.include?(n.id)) || n.applies(self)}
      end

      # :call-seq:
      #   natures => [:n1, :n2]
      #
      # Returns the project's natures.
      #
      # If no natures are defined on the project, the project will look for the 
      # natures defined in the parent's project and return them instead.
      # 
      def natures
        if @natures.nil?
          if parent
            @natures = parent.natures
          else
            @natures = []
          end
        end
        @natures  
      end

      protected

      # :call-seq:
      #   natures = [n1, n2]
      #
      # Sets the project's natures. Allows you to specify natures by calling
      # this accessor, or with the :natures property when calling #define.
      #
      # You can only set the natures once for a given project.
      def natures=(natures)
        raise 'Cannot set natures twice, or after reading its value' if @natures
        @natures = (natures.is_a? Array) ? natures : [natures]
      end
    end
  end 
end

class Buildr::Project
  include Buildr::Nature::NatureExtension
end