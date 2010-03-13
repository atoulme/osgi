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

describe OSGi::BundlePackage do
  
  it 'should have a nice string representation' do
    package = OSGi::BundlePackage.new("my.package", "1.0.0")
    package2 = OSGi::BundlePackage.new("my.package", "[1.0.0,2.0.0]")
    package.to_s.should == "Package my.package; version [1.0.0,infinite)"
    package2.to_s.should == "Package my.package; version [1.0.0,2.0.0]"
  end
  
  it 'should be able to know if it equals another bundle package' do
    package = OSGi::BundlePackage.new("my.package", "1.0.0")
    package2 = OSGi::BundlePackage.new("my.package", "1.0.0")
    package.should == package2
  end
  
  it 'should be able to know if it equals another bundle package with version range' do
    package = OSGi::BundlePackage.new("javax.servlet", "[2.4.0,3.0.0)")
    package2 = OSGi::BundlePackage.new("javax.servlet", "[2.4.0,3.0.0)")
    package.should == package2
  end
  
  it 'should define the same hash when bundles are equal' do
    package = OSGi::BundlePackage.new("my.package", "1.0.0")
    package2 = OSGi::BundlePackage.new("my.package", "1.0.0")
    package.hash.should == package2.hash
  end
end