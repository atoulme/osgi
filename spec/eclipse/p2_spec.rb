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

describe Buildr4OSGi::P2 do
  
  before(:each) do
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
    
    @bar = define("bar", :version => "1.0")
    site = @bar.package(:site)
    category = Buildr4OSGi::Category.new
    category.name = "category.id"
    category.label = "Some Label"
    category.description = "The category is described here"
    category.features<< @foo
    site.categories << category
    site  
    
  end
  
  it "should generate a p2 site" do
    @p2 = project("foo") do
      package(:p2_from_site).with :site => @bar
    end
    @p2.package(:p2_from_site).invoke
    
    
  end
end