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
  
  it "should package a project as a plugin with its internal properties files" do
    define_project
    Buildr::write "src/main/java/somefolder/hello.properties", "# Empty properties file"
     @plugin.package(:plugin).invoke
    File.exists?(@path).should be_true
    Zip::ZipFile.open(@path) do |zip|
      zip.find_entry("somefolder/hello.properties").should_not be_nil
    end
  end
  
  it "should work with subprojects" do
    Buildr::write "bar/plugin.xml", <<-PLUGIN_XML
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
    Buildr::write "bar/plugin.properties", <<-PLUGIN_PROPERTIES
marker=Hello marker
PLUGIN_PROPERTIES
    Buildr::write "bar/src/main/java/Main.java", "public class Main { public static void main(String[] args) {}}"
    define("plugin", :version => "1.0.0.001") do
      define("bar", :version => "2.0")
    end
    project("plugin:bar").package(:plugin).invoke
    File.basename(project("plugin:bar").package(:plugin).to_s).should == "bar-2.0.jar"
    Zip::ZipFile.open(project("plugin:bar").package(:plugin).to_s) do |zip|
      zip.find_entry("plugin.xml").should_not be_nil
      zip.find_entry("plugin.properties").should_not be_nil
      zip.find_entry("Main.class").should_not be_nil
    end
  end
  
  it "should work in the same way when doing package(:bundle)" do
    Buildr::write "bar/plugin.xml", <<-PLUGIN_XML
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
    Buildr::write "bar/plugin.properties", <<-PLUGIN_PROPERTIES
marker=Hello marker
PLUGIN_PROPERTIES
    Buildr::write "bar/src/main/java/Main.java", "public class Main { public static void main(String[] args) {}}"
    define("plugin", :version => "1.0.0.001") do
      define("bar", :version => "2.0")
    end
    project("plugin:bar").package(:bundle).invoke
    Zip::ZipFile.open(project("plugin:bar").package(:bundle).to_s) do |zip|
      zip.find_entry("plugin.xml").should_not be_nil
      zip.find_entry("plugin.properties").should_not be_nil
      zip.find_entry("Main.class").should_not be_nil
    end
  end
  
  it "should package the plugin manifest guessing the name and the version from the project information" do
    define_project
    @plugin = define("bar") do
      project.version = "1.0.0.001"
    end
    @path = @plugin.package(:plugin).to_s
     @plugin.package(:plugin).invoke
    File.exists?(@path).should be_true
    Zip::ZipFile.open(@path) do |zip|
      zip.find_entry("META-INF/MANIFEST.MF").should_not be_nil
      bundle = OSGi::Bundle.fromManifest(Manifest.read(zip.read("META-INF/MANIFEST.MF")), @path)
      bundle.should_not be_nil
      bundle.name.should == "bar" 
      bundle.version.should == "1.0.0.001"
    end
  end
  
  it "should package the plugin manifest guessing the name and the version from the project information (even though the version is defined inside the project)" do
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
  
  it 'should include all the resources present at the root of the plugin' do
    foo = define("foo", :version => "1.0.0") do
       package(:plugin).manifest["Bundle-Version"] = "2.0.0"
       Buildr::write "plugin.xml", ""
       mkpath "conf"
       Buildr::write "conf/log4j.properties", ""
     end
     foo.package(:plugin).invoke
     Zip::ZipFile.open(foo.package(:plugin).to_s) do |zip|
       zip.find_entry("conf/log4j.properties").should_not be_nil
     end
  end
  
  it 'should not include java files or classes by mistake' do
    Buildr::write "plugin.xml", ""
    Buildr::write "src/main/java/Main.java", "public class Main { public static void main(String[] args) {}}"
    Buildr::write "src/main/java/de/thing/HelloWorld.java", "package de.thing;public class HelloWorld {public static void main(String[] args) {}}"
    Buildr::write "customsrc/main/java/org/thing/Hello.java", ""
    Buildr::write "bin/org/thing/Hello.class", ""
    foo = define("foo", :version => "1.0.0") do
      compile.options.source = "1.5"
      compile.options.target = "1.5"
      
      package(:plugin).manifest["Bundle-Version"] = "2.0.0"   
    end
    foo.compile.invoke
    foo.package(:plugin).invoke
    Zip::ZipFile.open(foo.package(:plugin).to_s) do |zip|
      zip.find_entry("customsrc").should be_nil
      zip.find_entry("src").should be_nil
      zip.find_entry("src/main/java/de/thing/HelloWorld.java").should be_nil
      zip.find_entry("customsrc/main/java/org/thing/Hello.java").should be_nil
      zip.find_entry("bin/org/thing/Hello.class").should be_nil
      zip.find_entry("Main.class").should_not be_nil
       zip.find_entry("de/thing/HelloWorld.class").should_not be_nil
    end
  end
end

describe OSGi::BundleTask, "with packaging libs" do
  
  it "should package libraries under /lib" do
    foo = define("foo", :version => "1.0.0") do
      compile.using :target=>'1.5'
      package(:plugin).libs << SLF4J[0]
    end
    
    foo.package(:plugin).invoke
    Zip::ZipFile.open(foo.package(:plugin).to_s) do |zip|
      zip.find_entry("lib/slf4j-api-1.5.8.jar").should_not be_nil
    end
  end
  
  it "should add the libraries to the Bundle-Classpath" do
    foo = define("foo", :version => "1.0.0") do
      compile.using :target=>'1.5'
      package(:plugin).libs << SLF4J[0]
    end
    
    foo.package(:plugin).invoke
    Zip::ZipFile.open(foo.package(:plugin).to_s) do |zip|
      zip.find_entry("META-INF/MANIFEST.MF").should_not be_nil
      zip.read("META-INF/MANIFEST.MF").should match(/Bundle-Classpath: \.,lib\/slf4j-api-1\.5\.8\.jar/)
    end
  end
  
end

describe OSGi::BundleTask, "with existing manifests" do
  
  it "should use the values of an existing manifest" do
    Buildr::write "META-INF/MANIFEST.MF", "Bundle-SymbolicName: dev\nExport-Package: package1,\n package2"
    foo = define("foo", :version => "1.0.0") do
      compile.using :target=>'1.5'
      package(:plugin)
    end
    
    foo.package(:plugin).invoke
    Zip::ZipFile.open(foo.package(:plugin).to_s) do |zip|
      manifest =zip.read("META-INF/MANIFEST.MF")
      manifest.should match(/Export-Package: package1,package2/)
      manifest.should match(/Bundle-SymbolicName: dev/)
    end
  end
  
  it "should work with sub-projects" do
    Buildr::write "bar/META-INF/MANIFEST.MF", "Bundle-SymbolicName: dev\nExport-Package: package1,\n package2"
    define("foo", :version => "1.0.0") do
      define("bar", :version => "1.0") do
        package(:plugin)
      end
      compile.using :target=>'1.5'
      package(:plugin)
    end
    bar = project("foo:bar")
    bar.package(:plugin).invoke
    Zip::ZipFile.open(bar.package(:plugin).to_s) do |zip|
      manifest =zip.read("META-INF/MANIFEST.MF")
      manifest.should match(/Export-Package: package1,package2/)
      manifest.should match(/Bundle-SymbolicName: dev/)
    end
    
  end
  
  it "should always use the project version instead of the version defined in the manifest" do
    Buildr::write "META-INF/MANIFEST.MF", "Bundle-SymbolicName: dev\nExport-Package: package1,\n package2\nBundle-Version: 1.0.0"
    foo = define("foo", :version => "6.0.1.003") do
      compile.using :target=>'1.5'
      package(:plugin)
    end
    
    foo.package(:plugin).invoke
    Zip::ZipFile.open(foo.package(:plugin).to_s) do |zip|
      manifest =zip.read("META-INF/MANIFEST.MF")
      manifest.should match(/Bundle-Version: 6.0.1.003/)
      manifest.should match(/Bundle-SymbolicName: dev/)
    end
    
  end
  
end


describe OSGi::BundleProjects do
  
  it "should find a project packaging as an OSGi bundle" do
    foo = define("foo", :version => "1.0") do
      package(:bundle)
    end
    bundle_projects.should include(foo)
  end
  
  it "should not include a project that doesn't package as an OSGi bundle" do
    foo = define("foo", :version => "1.0") do
      package(:bundle)
    end
    bar = define("bar", :version => "1.0") do
      package(:jar)
    end
    bundle_projects.should include(foo)
    bundle_projects.should_not include(bar)
  end
end