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

describe OSGi::Registry do

  it 'should be possible to set containers from the Buildr settings' do
    pending "Doesn't work when using rake coverage"
    yaml = {"osgi" => ({"containers" => ["myContainer"]})}
    write 'home/.buildr/settings.yaml', yaml.to_yaml
    define("foo").osgi.registry.containers.should == ["myContainer"]
  end
  
  it 'should be accessible from a project' do
    define('foo').osgi.registry.should be_instance_of(OSGi::Registry)
  end
  
  
  
  it 'should be possible to set the containers from the OSGi environment variables' do
    ENV['OSGi'] = "foo;bar"
    define('foo').osgi.registry.containers.should == ["foo","bar"]
  end
  
  it 'should be possible to modify the containers in the registry before the resolved_instances method is called' do
    foo = define('foo')
    lambda {foo.osgi.registry.containers << "hello"}.should_not raise_error
    lambda {foo.osgi.registry.containers = ["hello"]}.should_not raise_error
  end
  
  it 'should throw an exception when modifying the containers in the registry after the resolved_instances method is called' do
    foo = define('foo')
    foo.osgi.registry.resolved_containers
    lambda {foo.osgi.registry.containers << "hello"}.should raise_error(TypeError)
    lambda {foo.osgi.registry.containers = ["hello"]}.should raise_error(RuntimeError, /Cannot set containers, containers have been resolved already/)
  end
end


describe OSGi::OSGi do
  
  it 'should add a new osgi method to projects' do
    define('foo').osgi.should be_instance_of(::OSGi::OSGi)
  end
  
  it 'should give a handle over the OSGi containers registry' do
    define('foo').osgi.registry.should be_instance_of(::OSGi::Registry)
  end
  
  it 'should help determine whether a package is part of the framework given by the execution environment' do
    foo = define('foo')
    foo.osgi.is_framework_package?("com.mypackage").should be_false
    foo.osgi.is_framework_package?(OSGi::JAVASE16.packages.first).should be_true
  end
  
end

describe OSGi::GroupMatcher do
  
  it 'should use osgi as the default group for an artifact' do
    OSGi::GroupMatcher.instance.group("hello").should == "osgi"
  end

  it 'should use org.eclipse  as the default group for Eclipse artifacts' do
    OSGi::GroupMatcher.instance.group("org.eclipse.core.resources").should == "org.eclipse"
  end  
  
  it 'should let users specify their own groups' do
    OSGi::GroupMatcher.instance.group_matchers << Proc.new {|name| "bar" if name.match /foo$/}
    OSGi::GroupMatcher.instance.group("org.eclipse.core.resources").should == "org.eclipse"
    OSGi::GroupMatcher.instance.group("hello").should == "osgi"
    OSGi::GroupMatcher.instance.group("org.eclipse.core.foo").should == "bar" 
  end
end