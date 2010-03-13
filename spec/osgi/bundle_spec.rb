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

require File.join(File.dirname(__FILE__), '..', 'spec_helpers')

Spec::Runner.configure do |config|
  config.include Buildr4OSGi::SpecHelpers
end

describe OSGi::Bundle do
  before :all do
    manifest = <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.1.R_20090912
Bundle-ActivationPolicy: Lazy
MANIFEST
    @bundle = OSGi::Bundle.fromManifest(Manifest.read(manifest), ".")
    manifest2 = <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources.x86; singleton:=true
Bundle-Version: 3.5.1.R_20090912
Bundle-ActivationPolicy: Lazy
Fragment-Host: org.eclipse.core.resources
MANIFEST
    @fragment = OSGi::Bundle.fromManifest(Manifest.read(manifest2), ".")
  end
  
  it 'should read from a manifest' do
    @bundle.name.should eql("org.eclipse.core.resources")
    @bundle.version.to_s.should eql("3.5.1.R_20090912")
    @bundle.lazy_start.should be_true
    @bundle.start_level.should eql(4)
  end
  
  it 'should be transformed as an artifact' do
    @bundle.to_s.should eql("org.eclipse:org.eclipse.core.resources:jar:3.5.1.R_20090912")
  end
  
  it 'should compare with its artifact definition' do
    (@bundle <=> "org.eclipse:org.eclipse.core.resources:jar:3.5.1.R_20090912").should == 0
  end
  
  it 'should recognize itself as a fragment' do
    @fragment.fragment?.should be_true
  end
  
  it 'should return nil if no name is given in the manifest' do
    manifest = <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-Version: 3.5.1.R_20090912
Bundle-ActivationPolicy: Lazy
MANIFEST
    OSGi::Bundle.fromManifest(Manifest.read(manifest), ".").should be_nil
  end
  
end

describe OSGi::Bundle, "fromProject" do
  it "should raise an exception if more than one bundle packaging is defined over the same project as it is not supported yet (BOSGI-16)" do
    foo = define "foo", :version => "1.0" do 
      package(:bundle) 
      package(:bundle, :file => "file.jar").with :manifest => {"Require-Bundle" => "some stuff"} 
    end
    lambda {OSGi::Bundle.fromProject(foo)}.should raise_error(RuntimeError, 
      /More than one bundle packaging is defined over the project .*, see BOSGI-16./)
  end
  
  it "should return nil if no bundle packaging is defined in the project" do
    foo = define "foo"
    OSGi::Bundle.fromProject(foo).should be_nil
  end
  
  it "should use the values placed in the META-INF/MANIFEST.MF file of the project" do
    manifest = <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.1.R_20090912
Bundle-ActivationPolicy: Lazy
MANIFEST
    Buildr::write "META-INF/MANIFEST.MF", manifest
    foo = define "foo", :version => "1.0" do
      project.group = "grp"
      package(:bundle)
    end
    bundle = OSGi::Bundle.fromProject(foo)
    bundle.lazy_start.should be_true
  end
  
  it "should use the manifest defined over the bundle packaging of the project" do
    foo = define "foo", :version => "1.0" do
      project.group = "grp"
      package(:bundle).with :manifest => {"Export-Package" => "p1,p2"}
    end
    bundle = ::OSGi::Bundle.fromProject(foo)
    bundle.exported_packages.should include(OSGi::BundlePackage.new("p1", nil))
  end
  
  it "should use the id of the project as the name of the bundle if none is defined" do
    foo = define "foo", :version => "1.0" do
      project.group = "grp"
      package(:bundle)
    end
    bundle = OSGi::Bundle.fromProject(foo)
    bundle.name.should == "foo"
    bundle.version.should == "1.0"
  end
  
  it "should use the values placed in the manifest, merged with those defined in the bundle packaging" do
    manifest = <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.1.R_20090912
Bundle-ActivationPolicy: Lazy
MANIFEST
    Buildr::write "META-INF/MANIFEST.MF", manifest
    foo = define "foo", :version => "1.0" do
      project.group = "grp"
      package(:bundle).with :manifest => {"Require-Bundle" => "org.apache.smthg;bundle-version=\"1.5.0\""}
    end
    bundle = OSGi::Bundle.fromProject(foo)
    bundle.name.should == "foo"
    bundle.version.should == "1.0"
    bundle.bundles.should include(OSGi::Bundle.new("org.apache.smthg", "1.5.0"))
  end
  
  it "should use the values placed in the manifest, merged with those defined in the bundle packaging, with no " do
    manifest = <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.1.R_20090912
Export-Package: org.mortbay.jetty.nio;uses:="org.mortbay.log,org.mortba
 y.thread,org.mortbay.io,org.mortbay.jetty,org.mortbay.util.ajax,org.mo
 rtbay.io.nio";version="6.1.20"
Bundle-ActivationPolicy: Lazy
MANIFEST
    Buildr::write "META-INF/MANIFEST.MF", manifest
    foo = define "foo", :version => "1.0" do
      project.group = "grp"
      package(:bundle).with :manifest => {"Require-Bundle" => "org.apache.smthg;bundle-version=\"1.5.0\""}
    end
    bundle = OSGi::Bundle.fromProject(foo)
    bundle.name.should == "foo"
    bundle.version.should == "1.0"
    bundle.bundles.should include(OSGi::Bundle.new("org.apache.smthg", "1.5.0"))
    bundle.exported_packages.should include(OSGi::BundlePackage.new("org.mortbay.jetty.nio", "6.1.20"))
    bundle.exported_packages.size.should == 1
  end
end 

describe "fragments" do
  before :all do
    manifest = <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.1.R_20090912
Bundle-ActivationPolicy: Lazy
MANIFEST
    manifest2 = <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources.x86; singleton:=true
Bundle-Version: 3.5.1.R_20090912
Bundle-ActivationPolicy: Lazy
Fragment-Host: org.eclipse.core.resources
MANIFEST
    @eclipse_instances = [createRepository("eclipse1")]
    Buildr::write File.join(@eclipse_instances.first, "plugins", "org.eclipse.core.resources-3.5.1.R_20090512", "META-INF", "MANIFEST.MF"), manifest
    Buildr::write File.join(@eclipse_instances.first, "plugins", "org.eclipse.core.resources.x86-3.5.1.R_20090512", "META-INF", "MANIFEST.MF"), manifest2
    @bundle = OSGi::Bundle.fromManifest(Manifest.read(manifest), ".")
    @fragment = OSGi::Bundle.fromManifest(Manifest.read(manifest2), ".")
  end
    
  
  it "should find the bundle fragments" do
    foo = define("foo")
    OSGi.registry.containers = @eclipse_instances.dup
    
    @bundle.fragments.should == [@fragment]
  end
  
end

