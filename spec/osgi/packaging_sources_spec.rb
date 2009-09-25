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

require File.join(File.dirname(__FILE__), '../spec_helpers')

Spec::Runner.configure do |config|
  config.include Buildr4OSGi::SpecHelpers
end

describe OSGi::BundleTask do
  
  def define_project
    Buildr::write "plugin.xml", <<-PLUGIN_XML
<?xml version="1.0" encoding="UTF-8"?>
<?eclipse version="3.2"?>
<plugin>
 <extension point="org.eclipse.core.runtime.preferences">
   <initializer class="org.intalio.preferenceInitializer"></initializer>
 </extension>
 <extension id="helloproblemmarker" name="%marker" point="org.eclipse.core.resources.markers">
       <super type="org.eclipse.core.resources.problemmarker"/>
       <persistent value="true"/>
 </extension>
</plugin>
PLUGIN_XML
    Buildr::write "plugin.properties", <<-PLUGIN_PROPERTIES
marker=Hello marker
PLUGIN_PROPERTIES
    Buildr::write "src/main/java/Main.java", "public class Main { public static void main(String[] args) {}}"
    @plugin = define("plugin", :version => "1.0.0.001")
    @path = @plugin.package(:sources).to_s
    
  end
  
  it "should package the sources as a normal Java -sources.jar" do
    define_project
    @plugin.package(:sources).invoke
    File.exists?(@path).should be_true
    Zip::ZipFile.open(@path) do |zip|
      zip.find_entry("Main.java").should_not be_nil
    end
  end

  it "should package a manifest for OSGi" do
    define_project
    @plugin.package(:sources).invoke
    File.exists?(@path).should be_true
    sourcesManifest = ::Buildr::Packaging::Java::Manifest.new(nil)
    Zip::ZipFile.open(@path) do |zip|
      zip.find_entry("Main.java").should_not be_nil
    end
  end


end