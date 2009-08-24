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
  
  it 'should write a valid feature.xml' do
    feature_xml = Buildr4OSGi::FeatureWriter.writeFeatureXml(
      [{:id => "myPlugin.id", :version => "2.3.4", :"download-size" => "2", :"install-size" => "3", :unpack => false},
      {:id => "myOtherPlugin.id", :version => "2.3.5", :"download-size" => "25", :"install-size" => "30", :unpack => false},
      {:id => "myBigPlugin.id", :version => "1.2.3.4", :"download-size" => "2", :"install-size" => "300", :unpack => true}],
        :id => "myId", 
        :version => "1.0.0.012", 
        :branding_plugin => "myPlugin.id", 
        :copyright => "Copyright (C) 1899-1908, Acme Inc.", 
        :update_sites => ["http://example.com/update1", "http://example.com/update2"], 
        :discovery_sites => ["http://example.com/discovery1", "http://example.com/discovery2", "http://example.com/discovery3"]
        )
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
    feature_xml = nil
    lambda { feature_xml = Buildr4OSGi::FeatureWriter.writeFeatureXml(
      [{:id => "myPlugin.id", :version => "2.3.4", :"download-size" => "2", :"install-size" => "3", :unpack => false},
      {:id => "myOtherPlugin.id", :version => "2.3.5", :"download-size" => "25", :"install-size" => "30", :unpack => false},
      {:id => "myBigPlugin.id", :version => "1.2.3.4", :"download-size" => "2", :"install-size" => "300", :unpack => true}],
        :id => "myId", 
        :version => "1.0.0.012", 
        :branding_plugin => nil, 
        :copyright => "Copyright (C) 1899-1908, Acme Inc.", 
        :update_sites => ["http://example.com/update1", "http://example.com/update2"], 
        :discovery_sites => ["http://example.com/discovery1", "http://example.com/discovery2", "http://example.com/discovery3"]
        ) }.should_not raise_error
    feature_xml.should_not match(/plugin="nil"/)
    feature_xml.should_not match(/plugin=""/)
  end
  
  it "should write a valid feature.properties" do
    feature_properties = Buildr4OSGi::FeatureWriter.writeFeatureProperties(
    :label => "my Feature", 
    :provider => "Acme Inc.", 
    :changesURL => "http://example.com/changes", 
    :description => "Best feature ever", 
    :licenseURL => "http://www.example.com/license", 
    :license => "This license is an example.", 
    :update_sites => ["Main update site", "Secondary update site"], 
    :discovery_sites => ["Discover us", "Discover our added value!", "Discover how cool we are"])
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
    feature_file = File.join(@foo.base_dir, "target", "foo-1.0.0-feature.jar")
    File.exists?(feature_file).should be_true
    Zip::ZipFile.open(feature_file) do |zip|
      zip.find_entry("eclipse/features/feature.xml").should_not be_nil
      zip.find_entry("eclipse/features/feature.properties").should_not be_nil
      zip.find_entry("eclipse/plugins/org.eclipse.debug.ui_3.4.1.v20080811_r341.jar").should_not be_nil
    end
  end
  
end