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

describe OSGi::ExecutionEnvironment do
  
  it 'should create a frozen object' do
    ee = OSGi::ExecutionEnvironment.new("example", "hello", ["com", "org"])
    ee.should be_frozen
    ee.packages.should be_frozen
  end
end

describe OSGi::ExecutionEnvironmentConfiguration do 
  
  before :all do
    @conf = OSGi::ExecutionEnvironmentConfiguration.new
  end
    
  
  it "should add the default execution environments" do
    @conf.send( :available_ee).values.should include OSGi::NONE, OSGi::CDC10FOUNDATION10, OSGi::CDC10FOUNDATION11, OSGi::J2SE12, OSGi::J2SE13, OSGi::J2SE14, OSGi::J2SE15, OSGi::JAVASE16, OSGi::JAVASE17, OSGi::OSGIMINIMUM10, OSGi::OSGIMINIMUM11, OSGi::OSGIMINIMUM12
  end
  
  it "should set JavaSE1.6 as the default execution environment" do
    @conf.current_execution_environment.should == OSGi::JAVASE16
  end
  
  it "should let the user define extra packages to be part of the execution environment" do
    @conf.extra_packages << "com.sum.nedia"
    @conf.extra_packages.should include("com.sum.nedia")
  end
end
     
  