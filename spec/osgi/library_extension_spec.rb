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

describe Buildr4OSGi::BuildLibraries do
  
  it 'should merge with the jars of the libraries' do
    library_project(SLF4J, "group", "foo", "1.0.0")
    
    foo = project("foo")
    lambda {foo.package(:library_project).invoke}.should_not raise_error
    jar = File.join(foo.base_dir, "target", "foo-1.0.0.jar")
    File.exists?(jar).should be_true
    Zip::ZipFile.open(jar) {|zip|
      zip.find_entry("org/slf4j/Marker.class").should_not be_nil  
    }
  end
  
  it 'should let users decide filters for exclusion when merging libraries' do
    library_project(SLF4J, "group", "foo", "1.0.0", :exclude => "org/slf4j/spi/*")
    foo = project("foo")
    lambda {foo.package(:library_project).invoke}.should_not raise_error
    jar = File.join(foo.base_dir, "target", "foo-1.0.0.jar")
    File.exists?(jar).should be_true
    Zip::ZipFile.open(jar) {|zip|
      zip.find_entry("org/slf4j/spi/MDCAdapter.class").should be_nil  
      zip.find_entry("META-INF/maven/org.slf4j/slf4j-api").should_not be_nil  
    }
    library_project(SLF4J, "group", "bar", "1.0.0", :include => ["org/slf4j/spi/MarkerFactoryBinder.class", "META-INF/*"])
    bar = project("bar")
    lambda {bar.package(:library_project).invoke}.should_not raise_error
    jar = File.join(bar.base_dir, "target", "bar-1.0.0.jar")
    File.exists?(jar).should be_true
    Zip::ZipFile.open(jar) {|zip|
      zip.find_entry("org/slf4j/spi/MDCAdapter.class").should be_nil  
      zip.find_entry("org/slf4j/spi/MarkerFactoryBinder.class").should_not be_nil  
      zip.find_entry("META-INF/maven/org.slf4j/slf4j-api").should_not be_nil  
    }
  end
  
  it 'should show the exported packages (the non-empty ones) under the Export-Package header in the manifest' do
    library_project(SLF4J, "group", "foo", "1.0.0")
    foo = project("foo")
    lambda {foo.package(:library_project).invoke}.should_not raise_error
    jar = File.join(foo.base_dir, "target", "foo-1.0.0.jar")
    File.exists?(jar).should be_true
    Zip::ZipFile.open(jar) {|zip|
      manifest = zip.find_entry("META-INF/MANIFEST.MF")
      manifest.should_not be_nil  
      contents = Manifest.read(zip.read(manifest))
      contents.first["Export-Package"].should_not be_nil
      contents.first["Export-Package"].keys.should include("org.slf4j.helpers")
      contents.first["Export-Package"].keys.should_not include("org")
    }
  end
  
  it 'should produce a zip of the sources' do
    library_project(SLF4J, "group", "foo", "1.0.0")
    foo = project("foo")
    lambda {foo.package(:sources).invoke}.should_not raise_error
    sources = File.join(foo.base_dir, "target", "foo-1.0.0-sources.zip")
    File.exists?(sources).should be_true
    Zip::ZipFile.open(sources) {|zip|
      zip.find_entry("org/slf4j/Marker.java").should_not be_nil
    }
  end   
  
  it 'should warn when the source of a library is unavailable' do
    library_project(DEBUG_UI, "group", "foo", "1.0.0")
    lambda {project("foo").package(:sources).invoke}.should show_warning(/Failed to download the sources/)    
  end
  
  it 'should raise an exception if passed a dependency it can\'t understand' do
    lambda {library_project(123, "group", "foo", "1.0.0")}.should raise_error(/Don't know how to interpret lib 123/)
  end
  
  it "should let the user specify manifest headers" do
    library_project(SLF4J, "group", "foo", "1.0.0", :manifest => {"Require-Bundle" => "org.bundle", "Some-Header" => "u1,u2"})
    foo = project("foo")
    foo.package(:library_project).invoke
    jar = File.join(foo.base_dir, "target", "foo-1.0.0.jar")
    File.exists?(jar).should be_true
    Zip::ZipFile.open(jar) {|zip|
      zip.find_entry("META-INF/MANIFEST.MF").should_not be_nil  
      manifest = zip.read("META-INF/MANIFEST.MF")
      manifest.should match(/Require-Bundle: org.bundle/)
      manifest.should match(/Some-Header: u1,u2/)
    }
  end
  
  it "should add a manifest method for users to grab the manifest of the library" do
    hash = manifest(DEBUG_UI)
    hash.should be_instance_of(Hash)
    hash["Bundle-SymbolicName"].should == "org.eclipse.debug.ui; singleton:=true"
  end
  
  it "should not add all the files at the root of the project" do
    write "somefile.txt", ""
    library_project(SLF4J, "group", "foo", "1.0.0")
    
    foo = project("foo")
    lambda {foo.package(:library_project).invoke}.should_not raise_error
    jar = File.join(foo.base_dir, "target", "foo-1.0.0.jar")
    File.exists?(jar).should be_true
    Zip::ZipFile.open(jar) {|zip|
      zip.find_entry("somefile.txt").should be_nil  
    }
  end
  
  it "should produce a jar" do
    library_project(SLF4J, "org.nuxeo.libs", "org.nuxeo.logging", "1.1.2",
    		 :manifest => {"Require-Bundle" => "org.apache.log4j"})
    foo = project("org.nuxeo.logging")
    foo.package(:library_project).invoke
    jar = File.join(foo.base_dir, "target", "org.nuxeo.logging-1.1.2.jar")
    File.exists?(jar).should be_true
  end    
end