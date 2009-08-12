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
require 'ruby-debug'
Debugger.start

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
    FileUtils.rm_rf Dir.pwd + "/tmp/eclipse1"
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
    Buildr::write "tmp/eclipse1/plugins/org.dude-3.5.0.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.dude; singleton:=true
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
Require-Bundle: com.ibm.icu;bundle-version="[3.3.0,4.0.0)",org.dude;bundle-version=3.5.0.R_20090512
MANIFEST
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.dependencies.invoke
    File.exist?('dependencies.yml').should be_true
    deps = YAML::load(File.read('dependencies.yml'))
    deps["foo"].size.should == 2
    artifact(deps["foo"][0]).to_hash[:id].should == "com.ibm.icu"
    artifact(deps["foo"][0]).to_hash[:version].should == "3.9.9.R_20081204"
  end
  
  it 'should give a version to the dependency even if none is specified' do
    foo = define('foo') {write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: com.ibm.icu;bundle-version="[3.3.0,4.0.0)",org.dude
MANIFEST
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.dependencies.invoke
    File.exist?('dependencies.yml').should be_true
    deps = YAML::load(File.read('dependencies.yml'))
    deps["foo"].size.should == 2 # there should be 2 dependencies
    artifact(deps["foo"][1]).to_hash[:id].should == "org.dude"
    artifact(deps["foo"][1]).to_hash[:version].should == "3.5.0.R_20090512"
  end
  
  it 'should pick a bundle when several match' do
    Buildr::write "tmp/eclipse2/plugins/org.eclipse.core.resources-3.5.0.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.0.R_20090512
MANIFEST
    Buildr::write "tmp/eclipse2/plugins/org.eclipse.core.resources-3.5.1.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.1.R_20090512
MANIFEST
    foo = define('foo') {write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: org.eclipse.core.resources;bundle-version="[3.3.0,3.5.2)"
MANIFEST
    }
    foo.osgi.registry.containers = [Dir.pwd + "/tmp/eclipse2"]
    foo.dependencies.invoke
    File.exist?('dependencies.yml').should be_true
    deps = YAML::load(File.read('dependencies.yml'))
    deps["foo"].size.should == 1
    artifact(deps["foo"][0].to_s).to_hash[:id].should == "org.eclipse.core.resources"
    artifact(deps["foo"][0]).to_hash[:version].should == "3.5.1.R_20090512"
  end
  
  it 'should resolve transitively all the jars needed' do
      Buildr::write "tmp/eclipse2/plugins/org.eclipse.core.resources-3.5.0.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources2; singleton:=true
Bundle-Version: 3.5.0.R_20090512
MANIFEST
      Buildr::write "tmp/eclipse2/plugins/org.eclipse.core.resources-3.5.1.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Require-Bundle: org.eclipse.core.resources2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.1.R_20090512
MANIFEST
      foo = define('foo') {write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: org.eclipse.core.resources;bundle-version="[3.3.0,3.5.2)"
MANIFEST
      }
      foo.osgi.registry.containers = [Dir.pwd + "/tmp/eclipse2"]
      foo.dependencies.invoke
      File.exist?('dependencies.yml').should be_true
      deps = YAML::load(File.read('dependencies.yml'))
      deps["foo"].size.should == 2
  end
  
end

describe OSGi::InstallTask do
  before :all do
    @eclipse_instances = [Dir.pwd + "/tmp/eclipse1"]
    download = Buildr::download((Dir.pwd + "/tmp/eclipse1/plugins/org.eclipse.debug.ui-3.4.1.v20080811_r341.jar") => "http://www.intalio.org/public/maven2/eclipse/org.eclipse.debug.ui/3.4.1.v20080811_r341/org.eclipse.debug.ui-3.4.1.v20080811_r341.jar")
    download.invoke
    Buildr::write "tmp/eclipse1/plugins/org.eclipse.core.resources-3.5.1.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Require-Bundle: org.eclipse.core.resources2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.1.R_20090512
MANIFEST
  end
  
  it 'should install the dependencies into the local Maven repository' do
    foo = define('foo') {write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: org.eclipse.debug.ui
MANIFEST
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.task('osgi:resolve:dependencies').invoke
    foo.task('osgi:install:dependencies').invoke
    
    File.exist?(artifact("osgi:org.eclipse.debug.ui:jar:3.4.1.v20080811_r341").to_s).should be_true
    
  end
  
  it 'should jar up OSGi bundles represented as directories' do
    foo = define('foo') {write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: org.eclipse.debug.ui,org.eclipse.core.resources;bundle-version=3.5.1.R_20090512
MANIFEST
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    
    foo.task('osgi:resolve:dependencies').invoke
    foo.task('osgi:install:dependencies').invoke
    
    File.exist?(artifact("osgi:org.eclipse.core.resources:jar:3.5.1.R_20090512").to_s).should be_true
  end
  
  it 'should upload dependencies to the releasing repository' do
    foo = define('foo') {write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: org.eclipse.debug.ui
MANIFEST
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    repositories.release_to = 'sftp://example.com/base'
    
    foo.task('osgi:resolve:dependencies').invoke
    URI.should_receive(:upload).once.
      with(URI.parse('sftp://example.com/base/osgi/org.eclipse.debug.ui/3.4.1.v20080811_r341/org.eclipse.debug.ui-3.4.1.v20080811_r341.jar'), 
      artifact("osgi:org.eclipse.debug.ui:jar:3.4.1.v20080811_r341").to_s, anything)
    URI.should_receive(:upload).once.
           with(URI.parse('sftp://example.com/base/osgi/org.eclipse.debug.ui/3.4.1.v20080811_r341/org.eclipse.debug.ui-3.4.1.v20080811_r341.pom'), 
           artifact("osgi:org.eclipse.debug.ui:jar:3.4.1.v20080811_r341").pom.to_s, anything)
    foo.task('osgi:upload:dependencies').invoke
    
    
  end
  
end

describe 'osgi:clean:dependencies' do
  it 'should install a nice and clean dependencies.yml for the project to depend on' do
    foo = define('foo') {
      define('bar')
      define('foobar')
    }
    foo.task('osgi:clean:dependencies').invoke
    File.exist?('dependencies.yml').should be_true
    deps = YAML::load(File.read('dependencies.yml'))
    deps["foo"].size.should == 0
     deps.keys.should include("foo:foobar")
    deps.keys.should include("foo:bar")
  end
end