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

describe OSGi::BuildLibraries do
  
  it 'should merge with the jars of the libraries' do
    pending
  end
  
  it 'should let users decide filters for exclusion when merging libraries' do
    pending
  end
  
  it 'should show the exported packages under the Export-Package header in the manifest' do
    pending
  end
  
  it 'should only list in the exported packages the ones that contain class files' do
    pending
  end
  
  it 'should produce a zip of the sources' do
    pending
  end   
  
  it 'should warn when the source of a library is unavailable' do
    pending
  end
  
  
end