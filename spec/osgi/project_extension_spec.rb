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

describe OSGi::ProjectExtension do
  
  it 'should add a new task to projects' do
    define('foo').dependencies.should be_instance_of(OSGi::DependenciesTask)
  end
  
  it 'should add a new osgi method to projects' do
    define('foo').osgi.should be_instance_of(OSGi::ProjectExtension::OSGi)
  end
  
  it 'should give a handle over the OSGi containers registry' do
    define('foo').osgi.registry.should be_instance_of(OSGi::Registry)
  end 
  
  it 'should give options to resolve bundle dependencies' do
    pending
  end
  
end

describe OSGi::DependenciesTask do

  before :all do
    @eclipse_instances = [Dir.pwd + "/tmp/eclipse1"]
    
    Buildr::write "tmp/eclipse1/plugins/com.ibm.icu-3.9.9.R_20081204/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: com.ibm.icu; singleton:=true
Bundle-Version: 3.9.9.R_20081204
MANIFEST
    Buildr::write "tmp/eclipse1/plugins/org.eclipse.core.resources-3.5.0.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.0.R_20090512
MANIFEST
  end
  
  it 'should help resolve dependencies' do
    foo = define('foo') {write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: com.ibm.icu,org.eclipse.core.resources
MANIFEST
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.manifest_dependencies.select {|b| b.name == "com.ibm.icu"}.should_not be_empty
  end
  
  it 'should resolve dependencies' do
    foo = define('foo') {write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: com.ibm.icu,org.eclipse.core.resources
MANIFEST
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.manifest_dependencies.select {|b| b.name == "com.ibm.icu"}.should_not be_empty
  end
  
  it 'should resolve dependencies with version requirements' do
    foo = define('foo') {write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: com.ibm.icu;bundle-version="[3.3.0,4.0.0)",org.eclipse.core.resources;bundle-version=3.5.0.R_20090512
MANIFEST
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.manifest_dependencies.select {|b| b.name == "com.ibm.icu"}.should_not be_empty
    foo.manifest_dependencies.select {|b| b.name == "com.ibm.icu" && b.version="[3.4.0,3.5.0)"}.should_not be_empty
    foo.manifest_dependencies.select {|b| b.name == "org.eclipse.core.resources" && b.version="3.5.0.R_20090512"}.should_not be_empty
  end
  
  it 'should write a file named dependencies.yml with the dependencies of the project' do
    foo = define('foo') {write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: com.ibm.icu;bundle-version="[3.3.0,4.0.0)",org.eclipse.core.resources;bundle-version=3.5.0.R_20090512
MANIFEST
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.dependencies.invoke
    File.exist?('dependencies.yml').should be_true
    deps = YAML::load(File.read('dependencies.yml'))
    deps["foo"].size.should == 2 # there should be 2 dependencies
    artifact(deps["foo"][0]).to_hash[:id].should == "com.ibm.icu"
    artifact(deps["foo"][0]).to_hash[:version].should == "3.9.9.R_20081204"
  end
  
  it 'should give a version to the dependency even if none is specified' do
    foo = define('foo') {write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: com.ibm.icu;bundle-version="[3.3.0,4.0.0)",org.eclipse.core.resources
MANIFEST
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.dependencies.invoke
    File.exist?('dependencies.yml').should be_true
    deps = YAML::load(File.read('dependencies.yml'))
    deps["foo"].size.should == 2 # there should be 2 dependencies
    artifact(deps["foo"][1]).to_hash[:id].should == "org.eclipse.core.resources"
    artifact(deps["foo"][1]).to_hash[:version].should == "3.5.0.R_20090512"
  end

end