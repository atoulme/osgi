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
#          Buildr.ant('org.eclipse.equinox.p2.publisher.UpdateSitePublisher') do |ant|
#            work_dir = File.join(project.base_dir, "target", "generated", "update-site")
#            ant.java :fork => true, :failonerror => true, :classname=>'org.eclipse.equinox.p2.publisher.UpdateSitePublisher' do
#              ant.arg :value => "metadataRepository" 
#              ant.arg :value => work_dir
#              ant.arg :value => "artifactRepository"
#              ant.arg :value => work_dir
#              ant.arg :value => "compress"
#              ant.arg :value => "publishArtifacts"
#            end
#          end
# http://wiki.eclipse.org/Equinox/p2/Publisher
#the p2.installer and the p2.agent don't work. currently debugging with a local eclipse sdk.
# download the app here: "org.eclipse.equinox.p2:installer:3.6M2-linux.gtk.x86:tgz"
# unzip it wherever it is.
# then invoke it on the cmd line `java -jar #{launcherLocation} -application ... -source #{siteLocation}`
#we need to give the ability to define an eclipse home that could be invoked as a replacement to this.
#          p2installer = Buildr::artifact("org.eclipse.platform:eclipse-platform:tgz:3.6M3-linux-gtk")
#          p2installer.invoke
#          p2installerHome = File.join(project.base_dir, "target", "p2installer")
#          Buildr::unzip(p2installerHome => p2installer).extract
#          p2installerHome = File.join(p2installerHome, "eclipse")
          
          #add the missing publisher plugin:
#          p2publisher = Buildr::artifact("org.eclipse.equinox.p2:org.eclipse.equinox.p2.publisher:jar:1.1.0.v20090831")
#          p2publisher.invoke
#          cp p2publisher.to_s, File.join(p2installerHome, "plugins/#{p2publisher.id}_#{p2publisher.version}.jar")

          siteWithoutP2 = project.package(:site)
          siteWithoutP2.invoke

          targetDir = File.join(project.base_dir, "target")
          targetP2Repo = File.join(project.base_dir, "p2repository");
          mkpath targetP2Repo
          Buildr::unzip(targetP2Repo=>siteWithoutP2.to_s).extract
          eclipseSDK = Buildr::artifact("org.eclipse:eclipse-SDK:zip:3.6M3-win32")
          eclipseSDK.invoke
          p2installerHome = File.dirname eclipseSDK.to_s#"/home/hmalphettes/proj/eclipses/eclipse-SDK-3.6M3";#"/home/hmalphettes/proj/eclipses/eclipse-3.6M2-SDK"
          Buildr::unzip( p2installerHome => eclipseSDK.to_s ).extract
          p2installerHome += "/eclipse"
          launcherPlugin = Dir.glob("#{p2installerHome}/plugins/org.eclipse.equinox.launcher_*")[0]
          
          application = "org.eclipse.equinox.p2.publisher.UpdateSitePublisher"
          #this is where the artifacts are published.
          metadataRepository_url = "file:#{targetP2Repo}"
          artifactRepository_url = metadataRepository_url
          metadataRepository_name = project.id + "_" + project.version
          artifactRepository_name = project.id + "_" + project.version
          source_absolutePath = targetP2Repo
          
          cmdline = "java -jar #{launcherPlugin} -application #{application} \
-metadataRepository #{metadataRepository_url} \
-artifactRepository #{artifactRepository_url} \
-metadataRepositoryName #{metadataRepository_name} \
-artifactRepositoryName #{artifactRepository_name} \
-source #{source_absolutePath} \
-configs gtk.linux.x86 \
-publishArtifacts \
-clean -consoleLog"
          puts "Invoking P2's metadata generation: #{cmdline}"
          result = `#{cmdline}`
          puts result
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

