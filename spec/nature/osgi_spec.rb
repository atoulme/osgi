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

describe 'Buildr::OSGiNature' do

  it 'should be registered as :osgi' do
    Buildr::Nature::Registry.get(:osgi).should_not nil
  end
  
  it 'should define some Eclipse options' do
    osgi = Buildr::Nature::Registry.get(:osgi)
    osgi.eclipse.natures.should include("org.eclipse.pde.PluginNature")
    osgi.eclipse.builders.should == ["org.eclipse.pde.ManifestBuilder", "org.eclipse.pde.SchemaBuilder"]
    osgi.eclipse.classpath_containers.should include("org.eclipse.pde.core.requiredPlugins")
  end
  
  it 'should apply when a plugin.xml file is present' do
    foo = define('foo') {write('plugin.xml')}
    osgi = Buildr::Nature::Registry.get(:osgi)
    osgi.applies(foo).should be_true
    foo.applicable_natures.should include(osgi)
  end
  
  it 'should apply when a OSGi-INF directory is present' do
    foo = define('foo') {write('OSGi-INF')}
    osgi = Buildr::Nature::Registry.get(:osgi)
    osgi.applies(foo).should be_true
    foo.applicable_natures.should include(osgi)
  end
  
  it 'should not apply when no OSGi specific files are present' do
    bar = define('bar') {write('src/main/c++')}
    osgi = Buildr::Nature::Registry.get(:osgi)
    osgi.applies(bar).should_not be_true
    bar.applicable_natures.should_not include(osgi)
  end
  
end