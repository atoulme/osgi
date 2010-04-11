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
  
  # For testing we use the gem requirements specified on the buildr4osgi.gemspec
  spec = Gem::Specification.load(File.expand_path('../osgi.gemspec', File.dirname(__FILE__)))
  spec.dependencies.each { |dep| gem dep.name, dep.version_requirements.to_s }
  # Make sure to load from these paths first, we don't want to load any
  # code from Gem library.
  $LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
  require 'osgi'
  
  [:info, :warn, :error, :puts].each do |severity|
    ::Object.class_eval do
      define_method severity do |*args|
        $messages ||= {}
        $messages[severity] ||= []
        $messages[severity].push(*args)
      end
    end
  end
  
  class MessageWithSeverityMatcher
    def initialize(severity, message)
      @severity = severity
      @expect = message
    end

    def matches?(target)
      $messages = {@severity => []}
      target.call
      return Regexp === @expect ? $messages[@severity].join('\n') =~ @expect : $messages[@severity].include?(@expect.to_s)
    end

    def failure_message
      "Expected #{@severity} #{@expect.inspect}, " +
        ($messages[@severity].empty? ? "no #{@severity} issued" : "found #{$messages[@severity].inspect}")
    end

    def negative_failure_message
      "Found unexpected #{$messages[@severity].inspect}"
    end
  end

  # Test if an info message was shown.  You can use a string or regular expression.
  #
  # For example:
  #   lambda { info 'ze test' }.should show_info(/ze test/)
  def show_info(message)
    MessageWithSeverityMatcher.new :info, message
  end

  # Test if a warning was shown. You can use a string or regular expression.
  #
  # For example:
  #   lambda { warn 'ze test' }.should show_warning(/ze test/)
  def show_warning(message)
    MessageWithSeverityMatcher.new :warn, message
  end

  # Test if an error message was shown.  You can use a string or regular expression.
  #
  # For example:
  #   lambda { error 'ze test' }.should show_error(/ze test/)
  def show_error(message)
    MessageWithSeverityMatcher.new :error, message
  end

  # Test if any message was shown (puts).  You can use a string or regular expression.
  #
  # For example:
  #   lambda { puts 'ze test' }.should show(/ze test/)
  def show(message)
    MessageWithSeverityMatcher.new :puts, message
  end
  
  # Writes contents in file
  def write(file, contents)
    FileUtils.mkpath File.dirname(file)
    File.open(file.to_s, 'wb') { |file| file.write contents.to_s }
  end
  
  OSGi_REPOS = File.expand_path File.join(File.dirname(__FILE__), "..", "tmp", "osgi")

  module MockInstanceWriter
    def registry=(i)
      @registry=i
    end
  end
  
  module SpecHelpers
    
    class << self
  
      def included(config)
        config.before(:all) {
          OSGi.extend MockInstanceWriter
        }
      
        config.before(:each) {
          OSGi.registry = OSGi::Registry.new
        }
        config.after(:all) {
          FileUtils.rm_rf OSGi_REPOS        
        }
    end
    
  end
  
  end
    
  def createRepository(name)
    repo = File.join(OSGi_REPOS, name)
    FileUtils.mkpath repo
    return repo
  end

end
