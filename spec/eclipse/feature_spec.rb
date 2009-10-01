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

describe Buildr4OSGi::FeatureWriter do
  
  before(:all) do
    class FeatureWriterTester
      
    end
    @f_w = FeatureWriterTester.new
    @f_w.extend Buildr4OSGi::FeatureWriter
  end
  it 'should write a valid feature.xml' do
   
    @f_w.feature_id = "myId"
    @f_w.version = "1.0.0.012"
    @f_w.branding_plugin = "myPlugin.id"
    @f_w.copyright = "Copyright (C) 1899-1908, Acme Inc."
    @f_w.update_sites = [{:url => "http://example.com/update1", :name => "Update site 1"}, 
      {:url => "http://example.com/update2", :name => "Update site 2"}]
    @f_w.discovery_sites = [{:url => "http://example.com/discovery1", :name => "Discovery site 1"}, 
      {:url => "http://example.com/discovery2", :name => "Discovery site 2"}, 
      {:url => "http://example.com/discovery3", :name => "Discovery site 3"}]
    feature_xml = @f_w.writeFeatureXml(
      [{:id => "myPlugin.id", :version => "2.3.4", :"download-size" => "2", :"install-size" => "3", :unpack => false},
      {:id => "myOtherPlugin.id", :version => "2.3.5", :"download-size" => "25", :"install-size" => "30", :unpack => false},
      {:id => "myBigPlugin.id", :version => "1.2.3.4", :"download-size" => "2", :"install-size" => "300", :unpack => true}],
      true)
    feature_xml.should == <<-FEATURE
<?xml version="1.0" encoding="UTF-8"?>
<feature plugin="myPlugin.id" id="myId" version="1.0.0.012" provider-name="%provider.name" label="%feature.name">
 <description url="%changesURL">%description</description>
 <copyright>Copyright (C) 1899-1908, Acme Inc.</copyright>
 <license url="%licenseURL">%license</license>
 <url>
  <update url="http://example.com/update1" label="%updatesite.name0"/>
  <update url="http://example.com/update2" label="%updatesite.name1"/>
  <discovery url="http://example.com/discovery1" label="%discoverysite.name0"/>
  <discovery url="http://example.com/discovery2" label="%discoverysite.name1"/>
  <discovery url="http://example.com/discovery3" label="%discoverysite.name2"/>
 </url>
 <plugin unpack="false" id="myPlugin.id" version="2.3.4" download-size="2" install-size="3"/>
 <plugin unpack="false" id="myOtherPlugin.id" version="2.3.5" download-size="25" install-size="30"/>
 <plugin unpack="true" id="myBigPlugin.id" version="1.2.3.4" download-size="2" install-size="300"/>
</feature>
FEATURE
  end
  
  it 'should not complain nor write an invalid feature.xml if the plugin argument is nil' do
    @f_w.feature_id = "myId"
    @f_w.version = "1.0.0.012"
    @f_w.branding_plugin = nil
    @f_w.copyright = "Copyright (C) 1899-1908, Acme Inc."
    @f_w.update_sites = [{:url => "http://example.com/update1", :name => "Update site 1"}, 
      {:url => "http://example.com/update2", :name => "Update site 2"}]
    @f_w.discovery_sites = [{:url => "http://example.com/discovery1", :name => "Discovery site 1"}, 
      {:url => "http://example.com/discovery2", :name => "Discovery site 2"}, 
      {:url => "http://example.com/discovery3", :name => "Discovery site 3"}]
    feature_xml = @f_w.writeFeatureXml(
      [{:id => "myPlugin.id", :version => "2.3.4", :"download-size" => "2", :"install-size" => "3", :unpack => false},
      {:id => "myOtherPlugin.id", :version => "2.3.5", :"download-size" => "25", :"install-size" => "30", :unpack => false},
      {:id => "myBigPlugin.id", :version => "1.2.3.4", :"download-size" => "2", :"install-size" => "300", :unpack => true}],
      true)
    feature_xml = nil
    lambda { feature_xml = @f_w.writeFeatureXml(
      [{:id => "myPlugin.id", :version => "2.3.4", :"download-size" => "2", :"install-size" => "3", :unpack => false},
      {:id => "myOtherPlugin.id", :version => "2.3.5", :"download-size" => "25", :"install-size" => "30", :unpack => false},
      {:id => "myBigPlugin.id", :version => "1.2.3.4", :"download-size" => "2", :"install-size" => "300", :unpack => true}]) }.should_not raise_error
    feature_xml.should_not match(/plugin="nil"/)
    feature_xml.should_not match(/plugin=""/)
  end
  
  it "should write a valid feature.properties" do
    @f_w.label = "my Feature"
    @f_w.provider = "Acme Inc."
    @f_w.changesURL = "http://example.com/changes"
    @f_w.description = "Best feature ever"
    @f_w.licenseURL = "http://www.example.com/license"
    @f_w.license = "This license is an example."
    @f_w.update_sites = [{:url => "http://example.com/update1", :name => "Update site 1"}, 
      {:url => "http://example.com/update2", :name => "Update site 2"}]
    @f_w.discovery_sites = [{:url => "http://example.com/discovery1", :name => "Discovery site 1"}, 
      {:url => "http://example.com/discovery2", :name => "Discovery site 2"}, 
      {:url => "http://example.com/discovery3", :name => "Discovery site 3"}]
    feature_properties = @f_w.writeFeatureProperties()
    feature_properties.should == <<-PROPERTIES
# Built by Buildr4OSGi

feature.name=my Feature
provider.name=Acme Inc.
changesURL=http://example.com/changes
description=Best feature ever
licenseURL=http://www.example.com/license
license=This license is an example.

PROPERTIES
  end
  
end


describe Buildr4OSGi::FeatureTask, "configuration" do
  
  it "should accept the feature parameters" do
    foo = define("foo", :version => "1.0.0")
    f = foo.package(:feature)
    lambda {
    f.plugins << "com.my:plugin:1.0:jar"
    f.label = "My feature"
    f.provider = "Acme Inc"
    f.copyright = "Copyright 1089-2345 Acme Inc"
    f.description = "The best feature ever"
    f.changesURL = "http://example.com/changes"
    f.license = "The license is too long to explain"
    f.licenseURL = "http://example.com/license"
    f.branding_plugin = "com.musal.ui"
    f.update_sites << {:url => "http://example.com/update", :name => "My update site"}
    f.discovery_sites = [{:url => "http://example.com/update2", :name => "My update site2"}, 
      {:url => "http://example.com/upup", :name => "My update site in case"}]
    }.should_not raise_error
  end
  
  it "should accept using an existing feature.xml without a feature.properties" do
    featurexml = <<-FEATURE
<feature/>
FEATURE
    Buildr::write "feature.xml", featurexml 
    foo = define("foo", :version => "1.0.0") 
    foo.package(:feature).feature_xml = "feature.xml"
    
    foo.package(:feature).invoke
    feature_file = File.join(foo.base_dir, "target", "foo-1.0.0.zip")
    Zip::ZipFile.open(feature_file) do |zip|
      zip.find_entry("eclipse/features/foo_1.0.0/feature.xml").should_not be_nil
      zip.read("eclipse/features/foo_1.0.0/feature.xml").should == featurexml
      zip.find_entry("eclipse/features/foo_1.0.0/feature.properties").should be_nil
    end
  end
  
  it "should accept using an existing feature.xml, and an optional feature.properties" do
    featurexml = <<-FEATURE
<feature/>
FEATURE
    featurep = <<-PROPS
key=value
PROPS
    Buildr::write "feature.xml", featurexml 
    Buildr::write "feature.properties", featurep
    foo = define("foo", :version => "1.0.0") 
    foo.package(:feature).feature_xml = "feature.xml"
    foo.package(:feature).feature_properties = "feature.properties"
    foo.package(:feature).invoke
    feature_file = File.join(foo.base_dir, "target", "foo-1.0.0.zip")
    Zip::ZipFile.open(feature_file) do |zip|
      zip.find_entry("eclipse/features/foo_1.0.0/feature.xml").should_not be_nil
      zip.read("eclipse/features/foo_1.0.0/feature.xml").should == featurexml
      zip.find_entry("eclipse/features/foo_1.0.0/feature.properties").should_not be_nil
      zip.read("eclipse/features/foo_1.0.0/feature.properties").should == featurep
    end
  end
  
  it "should generate feature.xml without externalizing strings when passed an existing feature.properties" do
    featurep = <<-PROPS
provider.0=My own provider
PROPS
    Buildr::write "feature.properties", featurep
    foo = define("foo", :version => "1.0.0") 
    f = foo.package(:feature)
    f.feature_properties = "feature.properties"
    f.plugins << DEBUG_UI
    f.label = "My feature"
    f.provider = "%provider.0"
    f.copyright = "Copyright 1089-2345 Acme Inc"
    f.description = "The best feature ever"
    f.changesURL = "http://example.com/changes"
    f.license = "The license is too long to explain"
    f.licenseURL = "http://example.com/license"
    foo.package(:feature).invoke
    feature_file = File.join(foo.base_dir, "target", "foo-1.0.0.zip")
    Zip::ZipFile.open(feature_file) do |zip|
      zip.find_entry("eclipse/features/foo_1.0.0/feature.xml").should_not be_nil
      feature_xml = zip.read("eclipse/features/foo_1.0.0/feature.xml")
      feature_xml.should_not match(/%label/)
      feature_xml.should match(/%provider\.0/)
      zip.find_entry("eclipse/features/foo_1.0.0/feature.properties").should_not be_nil
      zip.read("eclipse/features/foo_1.0.0/feature.properties").should == featurep
    end
  end
end
  
describe Buildr4OSGi::FeatureTask, " when running" do
  
  before do
    @foo = define("foo", :version => "1.0.0")
    f = @foo.package(:feature)
    f.plugins << DEBUG_UI
    f.label = "My feature"
    f.provider = "Acme Inc"
    f.description = "The best feature ever"
    f.changesURL = "http://example.com/changes"
    f.license = "The license is too long to explain"
    f.licenseURL = "http://example.com/license"
    f.branding_plugin = "com.musal.ui"
    f.update_sites << {:url => "http://example.com/update", :name => "My update site"}
    f.discovery_sites = [{:url => "http://example.com/update2", :name => "My update site2"}, 
      {:url => "http://example.com/upup", :name => "My update site in case"}]
  end
  
  it "should create a jar file with a eclipse/plugins and a eclipse/features structure" do
    @foo.package(:feature).invoke
    feature_file = File.join(@foo.base_dir, "target", "foo-1.0.0.zip")
    File.exists?(feature_file).should be_true
    Zip::ZipFile.open(feature_file) do |zip|
      zip.find_entry("eclipse/features/foo_1.0.0/feature.xml").should_not be_nil
      zip.find_entry("eclipse/features/foo_1.0.0/feature.properties").should_not be_nil
      zip.find_entry("eclipse/plugins/org.eclipse.debug.ui_3.4.1.v20080811_r341.jar").should_not be_nil
    end
  end
  
  it 'should complain if one of the dependencies is not a plugin' do
    @foo.package(:feature).plugins << LOG4J
    lambda { @foo.package(:feature).invoke}.should raise_error(
    /The dependency .* is not an Eclipse plugin: make sure the headers Bundle-SymbolicName and Bundle-Version are present in the manifest/)
  end
  
  it "should let the user tell which plugins should be unjarred" do
    f = @foo.package(:feature)
    f.plugins.clear
    @bar = define("bar", :version => "1.0.0") do
      package(:jar).with :manifest => {"Bundle-SymbolicName" => "bar", "Bundle-Version" => "1.0.0"}
    end
    f.plugins.<< DEBUG_UI, :unjarred => true
    f.plugins.<< @bar, :unjarred => true
    @foo.package(:feature).invoke
    feature_file = @foo.package(:feature).to_s
    File.exists?(feature_file).should be_true
    Zip::ZipFile.open(feature_file) do |zip|
      zip.find_entry("eclipse/plugins/org.eclipse.debug.ui_3.4.1.v20080811_r341/META-INF/MANIFEST.MF").should_not be_nil
      zip.find_entry("eclipse/plugins/bar_1.0.0/META-INF/MANIFEST.MF").should_not be_nil
    end
  end
  
end

describe Buildr4OSGi::FeatureTask, " package subprojects" do
  
  before do
    Buildr::write "bar/src/main/java/Hello.java", "public class Hello {}"
    @container = define("container") do
      @bar = define("bar", :version => "1.0.0") do
        package(:bundle)
        package(:sources)
      end
    end
    @foo = define("foo", :version => "1.0.0")
    f = @foo.package(:feature)
    f.plugins << project("container:bar")
    f.label = "My feature"
    f.provider = "Acme Inc"
    f.description = "The best feature ever"
    f.changesURL = "http://example.com/changes"
    f.license = "The license is too long to explain"
    f.licenseURL = "http://example.com/license"
    f.branding_plugin = "com.musal.ui"
    f.update_sites << {:url => "http://example.com/update", :name => "My update site"}
    f.discovery_sites = [{:url => "http://example.com/update2", :name => "My update site2"}, 
      {:url => "http://example.com/upup", :name => "My update site in case"}]
  end
  
  it "should create a jar file with the subproject packaged as a jar inside it" do
    @foo.package(:feature).invoke
    feature_file = @foo.package(:feature).to_s
    File.exists?(feature_file).should be_true
    Zip::ZipFile.open(feature_file) do |zip|
      zip.find_entry("eclipse/features/foo_1.0.0/feature.xml").should_not be_nil
      zip.find_entry("eclipse/features/foo_1.0.0/feature.properties").should_not be_nil
      zip.find_entry("eclipse/plugins/bar_1.0.0.jar").should_not be_nil
      zip.find_entry("eclipse/plugins/bar_1.0.0.jar").directory?.should be_false

    end
  end
  
  
end


describe Buildr4OSGi::FeatureTask, "packaged as SDK" do
  
  before do
    Buildr::write "bar/src/main/java/Hello.java", "public class Hello {}"
    @container = define("container") do
      project.group = "grp"
      @bar = define("bar", :version => "1.0.0") do
        package(:bundle)
        package(:sources)
      end
    end
    @foo = define("foo", :version => "1.0.0") do
      
      f = package(:feature)
      f.plugins.<< project("container:bar"), :unjarred => true
      f.label = "My feature"
      f.provider = "Acme Inc"
      f.description = "The best feature ever"
      f.changesURL = "http://example.com/changes"
      f.license = "The license is too long to explain"
      f.licenseURL = "http://example.com/license"
      f.branding_plugin = "com.musal.ui"
      f.update_sites << {:url => "http://example.com/update", :name => "My update site"}
      f.discovery_sites = [{:url => "http://example.com/update2", :name => "My update site2"}, 
        {:url => "http://example.com/upup", :name => "My update site in case"}]
      package(:sources)
    end
  end
  
  it "should create a jar file with the subproject packaged as a jar inside it" do
    @foo.package(:sources).invoke
    feature_file = @foo.package(:sources).to_s
    File.exists?(feature_file).should be_true
    Zip::ZipFile.open(feature_file) do |zip|
      zip.find_entry("eclipse/features/foo.sources_1.0.0/feature.xml").should_not be_nil
      zip.find_entry("eclipse/features/foo.sources_1.0.0/feature.properties").should_not be_nil
      zip.find_entry("eclipse/plugins/bar.sources_1.0.0.jar").should be_nil
      zip.find_entry("eclipse/plugins/bar.sources_1.0.0").directory?.should be_true
      zip.find_entry("eclipse/plugins/bar.sources_1.0.0/Hello.java").should_not be_nil
      
    end
  end
  
  
end