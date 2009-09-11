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

describe OSGi::ProjectExtension do
  
  it 'should give a way to take project dependencies' do
    define('foo').dependencies.should be_instance_of(Array)
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
    e1 = createRepository("eclipse1")
    @eclipse_instances = [e1]
    
    Buildr::write e1 + "/plugins/com.ibm.icu-3.9.9.R_20081204/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: com.ibm.icu; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Export-Package: my.package;version="1.0.0"
MANIFEST
    Buildr::write e1 + "/plugins/org.eclipse.core.resources-3.5.0.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.0.R_20090512
MANIFEST
    Buildr::write e1 + "/plugins/org.dude-3.5.0.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.dude; singleton:=true
Bundle-Version: 3.5.0.R_20090512
MANIFEST
  end

  it 'should resolve dependencies' do
    write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: com.ibm.icu,org.eclipse.core.resources
MANIFEST
    foo = define('foo', :version=> "1.0", :group => "grp" ) {
      package(:bundle)
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.manifest_dependencies.select {|b| b.name == "com.ibm.icu"}.should_not be_empty
  end
  
  it "should use projects as dependencies" do
    write "foo/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: bar
MANIFEST
    write "bar/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: bar
MANIFEST
    define('container') do
      project.version = "1.0"
      project.group = "grp"
      define('foo') do
        package(:bundle)
      end
      define('bar') do
        package(:bundle)
      end
    end
    project('container:foo').task('osgi:resolve:dependencies').invoke
    project('container:foo').manifest_dependencies.should include(project('container:bar'))
  end
  
  it "should use projects as dependencies, even if those are libraries projects" do
    write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: bar
MANIFEST
    library_project(SLF4J, "grp", "bar", "1.1")
    define('foo') do
      project.version = "1.0"
      project.group = "grp"
      package(:bundle)
    end
    project('foo').manifest_dependencies.should include(project('bar'))
  end
  
  it "should let library projects depend on each other" do
    library_project(DEBUG_UI, "grp", "bar", "1.0")
    library_project(SLF4J, "grp", "foo", "1.1", :manifest => {"Require-Bundle" => "bar"})
    
    project('foo').manifest_dependencies.should include(project('bar'))
  end
  
  it 'should resolve dependencies with version requirements' do
    write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: com.ibm.icu;bundle-version="[3.3.0,4.0.0)",org.eclipse.core.resources;bundle-version=3.5.0.R_20090512
MANIFEST
    foo = define('foo', :version => "1.0", :group => "grp") {
      package(:bundle)
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.manifest_dependencies.select {|b| b.name == "com.ibm.icu"}.should_not be_empty
    foo.manifest_dependencies.select {|b| b.name == "com.ibm.icu" && b.version="[3.4.0,3.5.0)"}.should_not be_empty
    foo.manifest_dependencies.select {|b| b.name == "org.eclipse.core.resources" && b.version="3.5.0.R_20090512"}.should_not be_empty
  end
  
  it "should resolve projects as dependencies with version requirements" do
    write "foo/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: bar;bundle-version="[1.0,3.5)"
MANIFEST
    write "bar/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: bar
MANIFEST
    define('container') do
      project.version = "1.1"
      
      define('foo') do
        package(:bundle)
      end
      define('bar') do
        package(:bundle)
      end
    end
    project('container').osgi.registry.containers = @eclipse_instances.dup
    project('container:foo').manifest_dependencies.should include(project('container:bar'))
  
  end
  
  it 'should resolve dependencies with package imports' do
    write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Import-Package: my.package
MANIFEST
    foo = define('foo', :version => "1.0", :group => "grp") {
      package(:bundle)
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.manifest_dependencies.select {|b| b.name == "com.ibm.icu"}.should_not be_empty
  end
  
  it "should resolve projects as dependencies with package imports" do
    write "foo/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Import-Package: my.very.own.package
MANIFEST
    write "bar/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: bar
Export-Package: my.very.own.package
MANIFEST
    write "bar2/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: bar2
Export-Package: my.very.own.packageuh
MANIFEST
    define('container') do
      project.version = "1.1"
      
      define('foo') do
        package(:bundle)
      end
      define('bar') do
        package(:bundle)
      end
      define('bar2') do
        package(:bundle)
      end
    end
    project('container').osgi.registry.containers = @eclipse_instances.dup
    project('container:foo').manifest_dependencies.should include(project('container:bar'))
    project('container:foo').manifest_dependencies.should_not include(project('container:bar2'))
  end
  
  it 'should resolve dependencies with package imports with version requirements' do
    write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Import-Package: my.package;version="0.9.0"
MANIFEST
    foo = define('foo', :version => "1.0", :group => "grp") {
      package(:bundle)
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.manifest_dependencies.select {|b| b.name == "com.ibm.icu"}.should_not be_empty
  end
  
  it "should resolve projects as dependencies with package imports" do
    write "foo/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Import-Package: my.very.own.package;version="0.9.0"
MANIFEST
    write "bar/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: bar
Export-Package: my.very.own.package;version="1.0.0"
MANIFEST
    write "bar2/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: bar2
Export-Package: my.very.own.package;version="0.5.0"
MANIFEST
    define('container') do
      project.version = "1.1"
      
      define('foo') do
        package(:bundle)
      end
      define('bar') do
        package(:bundle)
      end
      define('bar2') do
        package(:bundle)
      end
    end
    project('container').osgi.registry.containers = @eclipse_instances.dup
    project('container:foo').manifest_dependencies.should include(project('container:bar'))
    project('container:foo').manifest_dependencies.should_not include(project('container:bar2'))
  
  end
  
  it 'should write a file named dependencies.yml with the dependencies of the project' do
    write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: com.ibm.icu;bundle-version="[3.3.0,4.0.0)",org.dude;bundle-version=3.5.0.R_20090512
MANIFEST
    foo = define('foo', :version => "1.0", :group => "grp") {
      package(:bundle)
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.task('osgi:resolve:dependencies').invoke
    File.exist?('dependencies.yml').should be_true
    deps = YAML::load(File.read('dependencies.yml'))
    deps["foo"]["dependencies"].size.should == 2
    artifact(deps["foo"]["dependencies"][0]).to_hash[:id].should == "com.ibm.icu"
    artifact(deps["foo"]["dependencies"][0]).to_hash[:version].should == "3.9.9.R_20081204"
  end
  
  it 'should write a file named dependencies.yml with the projects required for the project' do
    write "foo/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: bar
MANIFEST
    write "bar/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: bar
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: com.ibm.icu;bundle-version="[3.3.0,4.0.0)",org.dude;bundle-version=3.5.0.R_20090512
MANIFEST
    define("container") do
      project.version = "1.0"
      project.group = "grp"
      foo = define('foo') {
        package(:bundle)
      }
      bar = define("bar") do
        package(:bundle)
      end
    end
    project('container').osgi.registry.containers = @eclipse_instances.dup
    project('container').task('osgi:resolve:dependencies').invoke
    File.exist?('dependencies.yml').should be_true
    deps = YAML::load(File.read('dependencies.yml'))
    deps["container-foo"]["projects"].size.should == 1
  end
  
  it 'should write a file named dependencies.yml with the projects required for the project' do
    write "foo/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: bar
MANIFEST
    write "bar/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: bar
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: com.ibm.icu;bundle-version="[3.3.0,4.0.0)",org.dude;bundle-version=3.5.0.R_20090512
MANIFEST
    define("container") do
      project.version = "1.0"
      project.group = "grp"
      foo = define('foo') {
        package(:bundle)
      }
      bar = define("bar") do
        package(:bundle)
      end
    end
    project('container').osgi.registry.containers = @eclipse_instances.dup
    project('container').task('osgi:resolve:dependencies').invoke
    File.exist?('dependencies.yml').should be_true
    deps = YAML::load(File.read('dependencies.yml'))
    deps["container-foo"]["projects"].size.should == 1
  end
  
  it 'should write a file named dependencies.yml and merge it as needed' do
    write "foo/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: bar
MANIFEST
    write "bar/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: bar
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: com.ibm.icu;bundle-version="[3.3.0,4.0.0)",org.dude;bundle-version=3.5.0.R_20090512
MANIFEST
    define("container") do
      project.version = "1.0"
      project.group = "grp"
      foo = define('foo') {
        package(:bundle)
      }
      bar = define("bar") do
        package(:bundle)
      end
    end
    project('container').osgi.registry.containers = @eclipse_instances.dup
    project('container:foo').task('osgi:resolve:dependencies').invoke
    project('container:bar').task('osgi:resolve:dependencies').invoke
    File.exist?('dependencies.yml').should be_true
    deps = YAML::load(File.read('dependencies.yml'))
    deps["container-foo"]["projects"].size.should == 1
    deps["container-bar"]["dependencies"].size.should == 2
  end
  
  it "should sort projects by name" do
    define("container") do
      project.version = "1"
      project.group = "grp"
    define('a'){
      package(:bundle)
    }
    define('b'){
      package(:bundle)
    }
    define('c'){
      package(:bundle)
    }
    define('d'){
      package(:bundle)
    }
    define('e'){
      package(:bundle)
    }
    end
    project('container').osgi.registry.containers = @eclipse_instances.dup
    project('container').task('osgi:resolve:dependencies').invoke
    File.exist?('dependencies.yml').should be_true
    File.read('dependencies.yml').should == <<-CONTENTS
--- 
container: 
  dependencies: []

  projects: []

container-a: 
  dependencies: []

  projects: []

container-b: 
  dependencies: []

  projects: []

container-c: 
  dependencies: []

  projects: []

container-d: 
  dependencies: []

  projects: []

container-e: 
  dependencies: []

  projects: []

CONTENTS
  end
  
  it 'should give a version to the dependency even if none is specified' do
    write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: com.ibm.icu;bundle-version="[3.3.0,4.0.0)",org.dude
MANIFEST
    foo = define('foo', :version => "1.0", :group => "grp") {
      package(:bundle)
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.task('osgi:resolve:dependencies').invoke
    File.exist?('dependencies.yml').should be_true
    deps = YAML::load(File.read('dependencies.yml'))
    deps["foo"]["dependencies"].size.should == 2 # there should be 2 dependencies
    artifact(deps["foo"]["dependencies"][1]).to_hash[:id].should == "org.dude"
    artifact(deps["foo"]["dependencies"][1]).to_hash[:version].should == "3.5.0.R_20090512"
  end
  
  it 'should pick a bundle when several match' do
    e2 = createRepository("eclipse2")
    Buildr::write e2 + "/plugins/org.eclipse.core.resources-3.5.0.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.0.R_20090512
MANIFEST
    Buildr::write e2 + "/plugins/org.eclipse.core.resources-3.5.1.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.1.R_20090512
MANIFEST
    write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: org.eclipse.core.resources;bundle-version="[3.3.0,3.5.2)"
MANIFEST
    foo = define('foo', :version => "1.0", :group => "grp") {
      package(:bundle)
    }
    foo.osgi.registry.containers = [e2]
    foo.task('osgi:resolve:dependencies').invoke
    File.exist?('dependencies.yml').should be_true
    deps = YAML::load(File.read('dependencies.yml'))
    deps["foo"]["dependencies"].size.should == 1
    artifact(deps["foo"]["dependencies"][0].to_s).to_hash[:id].should == "org.eclipse.core.resources"
    artifact(deps["foo"]["dependencies"][0]).to_hash[:version].should == "3.5.1.R_20090512"
  end
  
  it 'should resolve transitively all the jars needed' do
    e2 = createRepository("eclipse2")
      Buildr::write e2 + "/plugins/org.eclipse.core.resources-3.5.0.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources2; singleton:=true
Bundle-Version: 3.5.0.R_20090512
MANIFEST
      Buildr::write e2 + "/plugins/org.eclipse.core.resources-3.5.1.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Require-Bundle: org.eclipse.core.resources2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.1.R_20090512
MANIFEST
      write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: org.eclipse.core.resources;bundle-version="[3.3.0,3.5.2)"
MANIFEST
      foo = define('foo', :version => "1.0", :group => "grp") {
        package(:bundle)
      }
      foo.osgi.registry.containers = [e2]
      foo.task('osgi:resolve:dependencies').invoke
      File.exist?('dependencies.yml').should be_true
      deps = YAML::load(File.read('dependencies.yml'))
      
      deps["foo"]["dependencies"].size.should == 2
  end
  
end

describe OSGi::InstallTask do
  before :all do
    e1 = createRepository("eclipse1")
    @eclipse_instances = [e1]
    mkpath e1 + "/plugins"
    debug_ui = artifact("eclipse:org.eclipse.debug.ui:jar:3.4.1.v20080811_r341")
    debug_ui.invoke # download it from our fake remote repository
    cp debug_ui.to_s, (e1 + "/plugins/org.eclipse.debug.ui-3.4.1.v20080811_r341.jar")
    Buildr::write e1 + "/plugins/org.eclipse.core.resources-3.5.1.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Require-Bundle: org.eclipse.core.resources2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.1.R_20090512
MANIFEST
    cp_r File.join(File.dirname(__FILE__), "plugins", "org.eclipse.core.runtime.compatibility.registry_3.2.200.v20090429-1800"), e1 + "/plugins"
  end
  
  it 'should install the dependencies into the local Maven repository' do
    write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: org.eclipse.debug.ui
MANIFEST
    foo = define('foo', :version => "1.0", :group => "grp") {
      package(:bundle)
    }
    foo.osgi.registry.containers = @eclipse_instances.dup
    foo.dependencies
    foo.task('osgi:install:dependencies').invoke  
    File.exist?(artifact("osgi:org.eclipse.debug.ui:jar:3.4.1.v20080811_r341").to_s).should be_true
    
  end
  
  it 'should jar up OSGi bundles represented as directories' do
    write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: org.eclipse.debug.ui,
 org.eclipse.core.resources;bundle-version=3.5.1.R_20090512,
 org.eclipse.core.runtime.compatibility.registry
MANIFEST
    foo = define('foo', :version => "1.0", :group => "grp") do package(:bundle) end
    foo.osgi.registry.containers = @eclipse_instances.dup
    
    foo.task('osgi:resolve:dependencies').invoke
    foo.task('osgi:install:dependencies').invoke
    File.exist?(artifact("osgi:org.eclipse.core.resources:jar:3.5.1.R_20090512").to_s).should be_true
    Zip::ZipFile.open(artifact("osgi:org.eclipse.core.resources:jar:3.5.1.R_20090512").to_s) {|zip|
     zip.entries.empty?.should_not be_true 
    }
    File.exist?(artifact("osgi:org.eclipse.core.runtime.compatibility.registry:jar:3.2.200.v20090429-1800").to_s).should be_true
    
    Zip::ZipFile.open(artifact("osgi:org.eclipse.core.runtime.compatibility.registry:jar:3.2.200.v20090429-1800").to_s) {|zip|
     
     zip.entries.empty?.should_not be_true 
    }
  end
  
  it 'should upload dependencies to the releasing repository' do
    write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: org.eclipse.debug.ui,org.eclipse.core.resources
MANIFEST
    foo = define('foo', :version => "1.0", :group => "grp") {
      package(:bundle)
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
    URI.should_receive(:upload).once.
           with(URI.parse('sftp://example.com/base/osgi/org.eclipse.core.resources/3.5.1.R_20090512/org.eclipse.core.resources-3.5.1.R_20090512.pom'), 
           artifact("osgi:org.eclipse.core.resources:jar:3.5.1.R_20090512").pom.to_s, anything)
    URI.should_receive(:upload).once.
           with(URI.parse('sftp://example.com/base/osgi/org.eclipse.core.resources/3.5.1.R_20090512/org.eclipse.core.resources-3.5.1.R_20090512.jar'), 
           artifact("osgi:org.eclipse.core.resources:jar:3.5.1.R_20090512").to_s, anything)
    
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