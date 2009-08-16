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
    @bundle.to_s.should eql("osgi:org.eclipse.core.resources:jar:3.5.1.R_20090912")
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
    foo.osgi.registry.containers = @eclipse_instances.dup
    
    @bundle.fragments(foo).should == [@fragment]
  end
  
end