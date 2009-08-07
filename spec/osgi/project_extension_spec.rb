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
    define('foo').dependencies.should be_instance_of OSGi::DependenciesTask
  end
  
  it 'should add a new osgi method to projects' do
    define('foo').osgi.should be_instance_of OSGi::ProjectExtension::OSGi
  end
  
  it 'should give a handle over the OSGi containers registry' do
    define('foo').osgi.registry.should be_instance_of OSGi::Registry
  end 
  
  it 'should give options to resolve bundle dependencies' do
    pending
  end
  
  it 'should help resolve dependencies' do
    
    foo = define('foo') {write "META-INF/MANIFEST.MF", <<-MANIFEST
Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-SymbolicName: org.osgi.something; singleton:=true
Bundle-Version: 3.9.9.R_20081204
Require-Bundle: org.osgi.else,org.osgi.basics
MANIFEST
    }
    foo.osgi.registry.containers << ""
    pending "create the containers and make the resolving happen."
    print foo.dependencies
  end

end