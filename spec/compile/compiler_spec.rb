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

describe Buildr4OSGi::Compiler::OSGiC do
  it "should compile a Java project just in the same way javac does" do
    
  end
  
  javac_spec = File.read(File.join(File.dirname(__FILE__), "..", "..", "buildr", "spec", "java", "compiler_spec.rb"))
  javac_spec = javac_spec.match(Regexp.escape("require File.join(File.dirname(__FILE__), '../spec_helpers')\n")).post_match
  javac_spec.gsub!("javac", "osgic")
  eval(javac_spec)
end
