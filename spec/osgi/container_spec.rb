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

describe OSGi::Container do

  before :all do
    e1= createRepository("eclipse1")
    e2= createRepository("eclipse2")
    @eclipse_instances = [e1, e2]
    
    Buildr::write e1 + "/plugins/com.ibm.icu-3.9.9.R_20081204/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: com.ibm.icu; singleton:=true
Bundle-Version: 3.9.9.R_20081204
MANIFEST
    Buildr::write e1 + "/plugins/org.eclipse.core.resources-3.5.0.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.0.R_20090512
MANIFEST
    Buildr::write e1 + "/plugins/org.fragments-3.5.0.R_20090512/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.fragment; singleton:=true
Fragment-Host: org.eclipse.core.resources
Bundle-Version: 3.5.0.R_20090512
MANIFEST
    Buildr::write e2 + "/plugins/org.eclipse.core.resources-3.5.1.R_20090912/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.core.resources; singleton:=true
Bundle-Version: 3.5.1.R_20090912
MANIFEST
    Buildr::write e2 + "/plugins/org.eclipse.ui-3.4.2.R_20090226/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.ui; singleton:=true
Bundle-Version: 3.4.2.R_20090226
MANIFEST
  
    Buildr::write e2 + "/plugins/org.eclipse.ui-3.5.0.M_20090107/META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.eclipse.ui; singleton:=true
Bundle-Version: 3.5.0.M_20090107
MANIFEST
  end
  
  it 'should be able to create an OSGi container instance on a folder'  do
    lambda {OSGi::Container.new(@eclipse_instances.first)}.should_not raise_error
  end
  
  it 'should be able to list the bundles present in the container' do
    e1 = OSGi::Container.new(@eclipse_instances.first)
    bundles = e1.bundles.select {|bundle| bundle.name == "com.ibm.icu"}
    bundles.size.should eql(1)
  end
  
  it 'should be able to list the fragments present in the container' do
    e1 = OSGi::Container.new(@eclipse_instances.first)
    e1.fragments.size.should eql(1)
  end
  
  it 'should find a specific bundle in the container' do
    e2 = OSGi::Container.new(@eclipse_instances.last)
    e2.find(:name=> "org.eclipse.ui", :version => "3.5.0.M_20090107").should_not be_empty
  end
  
  it 'should find a specific fragment in the container' do
    e1 = OSGi::Container.new(@eclipse_instances.first)
    e1.find_fragments(:name=> "org.fragment").should_not be_empty
  end
end