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

describe 'Buildr::JavaNature' do

  it 'should be registered as :java' do
    Buildr::Nature::Registry.get(:java).should_not be_nil
  end
  
  it 'should define some Eclipse options' do
    java = Buildr::Nature::Registry.get(:java)
    java.eclipse.natures.should include("org.eclipse.jdt.core.javanature")
    java.eclipse.builders.should include("org.eclipse.jdt.core.javabuilder")
    java.eclipse.classpath_containers.should include("org.eclipse.jdt.launching.JRE_CONTAINER")
  end
  
  it 'should apply when a java source folder is present' do
    foo = define('foo') {write('src/main/java')}
    java = Buildr::Nature::Registry.get(:java)
    java.applies(foo).should be_true
    foo.applicable_natures.should include(java)
  end
  
  it 'should not apply when no java source folder is present' do
    bar = define('bar') {write('src/main/c++')}
    java = Buildr::Nature::Registry.get(:java)
    java.applies(bar).should_not be_true
    bar.applicable_natures.should_not include(java)
  end
  
end