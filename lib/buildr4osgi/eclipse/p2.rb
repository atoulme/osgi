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

  module P2

    include Extension

    def package_as_p2_from_site(file_name)
      task = UpdateSitePublisherTask.define_task(file_name)
      task.send :associate_with, self
      return task
    end
    
    def package_as_p2_from_site_spec(spec)
      spec.merge(:type => :zip, :classifier => "p2", :id => name.split(":").last)
    end

    class UpdateSitePublisherTask < Rake::FileTask

      attr_accessor :site
      attr_reader :project

      def initialize(*args) #:nodoc:
        super
        enhance do
          Buildr.ant('org.eclipse.equinox.p2.publisher.UpdateSitePublisher') do |ant|
            work_dir = File.join(project.base_dir, "target", "generated", "update-site")
            ant.java :fork => true, :failonerror => true, :classname=>'org.eclipse.equinox.p2.publisher.UpdateSitePublisher' do
              ant.arg :value => "metadataRepository" 
              ant.arg :value => work_dir
              ant.arg :value => "artifactRepository"
              ant.arg :value => work_dir
              ant.arg :value => "compress"
              ant.arg :value => "publishArtifacts"
            end
          end
        end
      end

      # :call-seq:
      #   with(options) => self
      #
      # Passes options to the task and returns self. 
      #
      def with(options)
        options.each do |key, value|
          begin
            send "#{key}=", value
          rescue NoMethodError
            raise ArgumentError, "#{self.class.name} does not support the option #{key}"
          end
        end
        self
      end

      private 

      def associate_with(project)
        @project = project
      end

    end
  end
end

class Buildr::Project
  include Buildr4OSGi::P2
end

