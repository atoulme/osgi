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

describe 'Buildr::ScalaNature' do

  it 'should be registered as :scala' do
    Buildr::Nature::Registry.get(:scala).should_not nil
  end
  
  it 'should define some Eclipse options' do
    scala = Buildr::Nature::Registry.get(:scala)
    scala.eclipse.natures.should == ["ch.epfl.lamp.sdt.core.scalanature", "org.eclipse.jdt.core.javanature"] 
    scala.eclipse.builders.should include("ch.epfl.lamp.sdt.core.scalabuilder")
    scala.eclipse.classpath_containers.should == ["ch.epfl.lamp.sdt.launching.SCALA_CONTAINER", "org.eclipse.jdt.launching.JRE_CONTAINER"]
  end
  
  it 'should apply when a scala source folder is present' do
    foo = define('foo') {write('src/main/scala')}
    scala = Buildr::Nature::Registry.get(:scala)
    scala.applies(foo).should be_true
    foo.applicable_natures.should include(scala)
  end
  
  it 'should not apply when no scala source folder is present' do
    bar = define('bar') {write('src/main/c++')}
    scala = Buildr::Nature::Registry.get(:scala)
    scala.applies(bar).should_not be_true
    bar.applicable_natures.should_not include(scala)
  end
  
end