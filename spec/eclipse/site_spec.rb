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

describe Buildr4OSGi::SiteWriter do
  
  before(:each) do
    class SiteWriterTester
      
    end
    @f_w = SiteWriterTester.new
    @f_w.extend Buildr4OSGi::SiteWriter
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
      #package(:sources)
    end
  end
  
  it "should write a valid site.xml" do
    @f_w.description = "Description"
    @f_w.description_url = "http://www.example.com/description"
    category = Buildr4OSGi::Category.new
    category.name = "category.id"
    category.label = "Some Label"
    category.description = "The category is described here"
    category.features<< @foo
    @f_w.categories << category
    @f_w.writeSiteXml({@foo.package(:feature).to_s => {:id => "foo", :version => "1.0.0"}}).should == <<-SITE_XML
<?xml version="1.0" encoding="UTF-8"?>
<site pack200="false">
 <description url="http://www.example.com/description">Description</description>
 <category-def name="category.id" label="Some Label">
  <description>The category is described here</description>
 </category-def>
 <feature url="features/foo_1.0.0.jar" version="1.0.0" patch="false" id="foo">
  <category name="category.id"/>
 </feature>
</site>
SITE_XML
  end
  
  it "should create a zip file containing site.xml at its root" do
    @bar = define("bar", :version => "1.0")
    site = @bar.package(:site)
    category = Buildr4OSGi::Category.new
    category.name = "category.id"
    category.label = "Some Label"
    category.description = "The category is described here"
    category.features<< @foo
    site.categories << category
    site.invoke
    File.should exist(site.to_s)
    Zip::ZipFile.open(site.to_s) do |zip|
      print zip.entries.join("\n")
      print zip.read("site.xml")
      zip.find_entry("plugins").should_not be_nil
      zip.find_entry("features").should_not be_nil
    end
  end
  
  
end