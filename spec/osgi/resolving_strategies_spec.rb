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

describe OSGi::BundleResolvingStrategies do
  
  before(:all) do
    @bundles = [OSGi::Bundle.new("art", "1.0"), OSGi::Bundle.new("art", "2.0"), 
      OSGi::Bundle.new("art", "2.0.1"), OSGi::Bundle.new("art", "3.0")]
    
  end
  
  it 'should use latest by default to resolve bundle dependencies' do
    OSGi.options.bundle_resolving_strategy.should eql(:latest)
  end
  
  describe 'latest' do
    
    it 'should return the bundle with the latest version' do
      OSGi::BundleResolvingStrategies.latest(@bundles).should == @bundles.last
    end
    
  end
  
  describe 'oldest' do
    
    it 'should return the bundle with the oldest version' do
      OSGi::BundleResolvingStrategies.oldest(@bundles).should == @bundles.first
    end
    
  end
  
  describe 'prompt' do
    
    it 'should prompt the user to choose a bundle' do
      input = $stdin
      $stdin = StringIO.new
      $stdin.should_receive(:gets).and_return("i\n")
      $stdin.should_receive(:gets).and_return("256\n")
      $stdin.should_receive(:gets).and_return("2\n")
      lambda { 
        OSGi::BundleResolvingStrategies.prompt(@bundles).should == @bundles[1]
      }.should show("Invalid index")
      $stdin = input
    end
    
  end
  
end

describe OSGi::PackageResolvingStrategies do
  
  before(:all) do
    @bundles = [OSGi::Bundle.new("art", "1.0"), OSGi::Bundle.new("art", "2.0"), 
      OSGi::Bundle.new("art", "2.0.1"), OSGi::Bundle.new("art", "3.0")]
    
  end
  
  it 'should use all by default to resolve package dependencies' do
    OSGi.options.package_resolving_strategy.should eql(:all)
  end
  
  describe 'all' do
    
    it 'should take all the bundles' do
      OSGi::PackageResolvingStrategies.all(::OSGi::BundlePackage.new("com.package", "1.0"), @bundles).should == @bundles
    end
    
  end
  
  describe 'prompt' do
    
    it 'should prompt the user to choose a bundle' do
      input = $stdin
      $stdin = StringIO.new
      $stdin.should_receive(:gets).and_return("2\n")
      OSGi::PackageResolvingStrategies.prompt(::OSGi::BundlePackage.new("com.package", "1.0"), @bundles).should == [@bundles[1]]
      $stdin = input
    end
    
    it 'should complain if the user enters an invalid index' do
      input = $stdin
      $stdin = StringIO.new
      $stdin.should_receive(:gets).and_return("i\n")
      $stdin.should_receive(:gets).and_return("256\n")
      $stdin.should_receive(:gets).and_return("2\n")
      lambda { 
        OSGi::PackageResolvingStrategies.prompt(::OSGi::BundlePackage.new("com.package", "1.0"), @bundles).should == [@bundles[1]]
      }.should show("Invalid index")
      $stdin = input
    end
    
    it 'should let the user select all bundles' do
      input = $stdin
      $stdin = StringIO.new
      $stdin.should_receive(:gets).and_return("A\n")
      OSGi::PackageResolvingStrategies.prompt(::OSGi::BundlePackage.new("com.package", "1.0"), @bundles).should == @bundles
      $stdin = input
    end
    
  end
  
end