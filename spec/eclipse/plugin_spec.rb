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

describe Buildr4OSGi::PluginTask do
  
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
    @path = @plugin.package(:plugin).to_s
    
  end
  
  it "should package a project as a normal Java project" do
    define_project
     @plugin.package(:plugin).invoke
    File.exists?(@path).should be_true
    Zip::ZipFile.open(@path) do |zip|
      zip.find_entry("Main.class").should_not be_nil
      
    end
  end
  
  it "should package a project as a plugin with plugin.xml, plugin.properties" do
    define_project
     @plugin.package(:plugin).invoke
    File.exists?(@path).should be_true
    Zip::ZipFile.open(@path) do |zip|
      zip.find_entry("plugin.xml").should_not be_nil
      zip.find_entry("plugin.properties").should_not be_nil
    end
  end
  
  it "should package the plugin manifest guessing the name and the version from the project information" do
    define_project
     @plugin.package(:plugin).invoke
    File.exists?(@path).should be_true
    Zip::ZipFile.open(@path) do |zip|
      zip.find_entry("META-INF/MANIFEST.MF").should_not be_nil
      bundle = OSGi::Bundle.fromManifest(Manifest.read(zip.read("META-INF/MANIFEST.MF")), @path)
      bundle.should_not be_nil
      bundle.name.should == "plugin" 
      bundle.version.should == "1.0.0.001"
    end
  end
  
  it "should let the project override the default Bundle-SymbolicName value" do
    foo = define("foo", :version => "2.0.0.58") do
      package(:plugin).manifest["Bundle-SymbolicName"] = "myValue"
      Buildr::write "plugin.xml", ""
    end
    foo.package(:plugin).invoke
    File.exists?(foo.package(:plugin).to_s).should be_true
    Zip::ZipFile.open(foo.package(:plugin).to_s) do |zip|
      zip.find_entry("META-INF/MANIFEST.MF").should_not be_nil
      bundle = OSGi::Bundle.fromManifest(Manifest.read(zip.read("META-INF/MANIFEST.MF")), foo.package(:plugin).to_s)
      bundle.should_not be_nil
      bundle.name.should == "myValue" 
      bundle.version.should == "2.0.0.58"
    end
  end
  
  it "should derive the Bundle-Name value from the project comment or name" do
    foo = define("foo", :comment => "most awesome project", :version => "1.0.0") do
      Buildr::write "plugin.xml", ""
    end
    foo.package(:plugin).invoke
    File.exists?(foo.package(:plugin).to_s).should be_true
    Zip::ZipFile.open(foo.package(:plugin).to_s) do |zip|
      zip.find_entry("META-INF/MANIFEST.MF").should_not be_nil
      zip.read("META-INF/MANIFEST.MF").should match(/Bundle-Name: most awesome project/)
    end
  end
  
  it "should let the project override the version" do
   foo = define("foo", :version => "1.0.0") do
     package(:plugin).manifest["Bundle-Version"] = "2.0.0"
     Buildr::write "plugin.xml", ""
   end
   foo.package(:plugin).invoke
   File.exists?(foo.package(:plugin).to_s).should be_true
   Zip::ZipFile.open(foo.package(:plugin).to_s) do |zip|
     zip.find_entry("META-INF/MANIFEST.MF").should_not be_nil
     bundle = OSGi::Bundle.fromManifest(Manifest.read(zip.read("META-INF/MANIFEST.MF")), foo.package(:plugin).to_s)
     bundle.should_not be_nil
     bundle.name.should == "foo" 
     bundle.version.should == "2.0.0"
   end
  end
  
  it 'should issue a warning if plugin.xml or plugin.properties are missing' do
    foo = define("foo", :version => "1.0.0")
    lambda {foo.package(:plugin).invoke}.should show_warning("plugin.xml is missing. Please add it to your project.") && 
      show_warning("plugin.properties is missing. Please add it to your project.")
  end
end