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

unless defined?(SpecHelpers)
  
  module SandboxHook
    
    def SandboxHook.included(spec_helpers)
      # For testing we use the gem requirements specified on the buildr4osgi.gemspec
      spec = Gem::Specification.load(File.expand_path('../buildr4osgi.gemspec', File.dirname(__FILE__)))
      spec.dependencies.each { |dep| gem dep.name, dep.version_requirements.to_s }
      # Make sure to load from these paths first, we don't want to load any
      # code from Gem library.
      $LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
      require 'buildr4osgi'
    end
  end
  
  require File.join(File.dirname(__FILE__), "/../buildr/spec/spec_helpers.rb")
  
  #Change the local Maven repository so that it isn't deleted everytime:
  fake_local = Buildr::repositories.local
  HELPERS_REPOSITORY = File.expand_path(File.join(File.dirname(__FILE__), "tmp", "remote"))
  Buildr::repositories.local = HELPERS_REPOSITORY
  slf4j = Buildr::group(%w{ slf4j-api slf4j-log4j12 jcl104-over-slf4j }, :under=>"org.slf4j", :version=>"1.5.8")
  LOG4J = "log4j:log4j:jar:1.2.15"
  SLF4J = slf4j
  DEBUG_UI = "eclipse:org.eclipse.debug.ui:jar:3.4.1.v20080811_r341"
  Buildr::repositories.remote << "http://www.intalio.org/public/maven2"
  artifact(DEBUG_UI).invoke # download it once!
  artifact(LOG4J).invoke
  for lib in SLF4J do
    artifact(lib).invoke
    artifact(artifact(lib).to_hash.merge(:classifier => "sources")).invoke
  end
  Buildr::repositories.local = fake_local
  
  module Buildr4OSGi::SpecHelpers

    OSGi_REPOS = File.expand_path File.join(File.dirname(__FILE__), "..", "tmp", "osgi")

    module MockInstanceWriter
      def registry=(i)
        @registry=i
      end
    end
    
    class << self

      def included(config)
        config.before(:all) {
          OSGi.extend MockInstanceWriter
        }
        
        config.before(:each) {
          remoteRepositoryForHelpers()
          OSGi.registry = OSGi::Registry.new
        }
        config.after(:all) {
          FileUtils.rm_rf Buildr4OSGi::SpecHelpers::OSGi_REPOS
          
        }
      end
    end
    
    def createRepository(name)
      repo = File.join(OSGi_REPOS, name)
      mkpath repo
      return repo
    end
    
    def remoteRepositoryForHelpers()
      repositories.remote << "file://#{HELPERS_REPOSITORY}"
    end
    
    
  end
  
  Spec::Runner.configure do |config|
    config.include Buildr4OSGi
    
    
  end

end
