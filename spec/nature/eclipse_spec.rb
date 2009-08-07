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

describe Buildr::Nature::Eclipse do
  after :all do
    #empty the registry.
    module Buildr
      module Nature
        module Registry
          @registered_natures = DEFAULT.dup
        end
      end
    end
  end
  
  it 'should replace the default Eclipse object' do
    define('foo').eclipse.should be_instance_of(Buildr::Nature::Eclipse::Eclipse)
  end
  
  it 'should use project natures to define Eclipse options' do
    class DummyNature < Buildr::DefaultNature
      def initialize()
        super(:dummy)
        eclipse.natures = 'MyNature'
      end
    end
    Buildr::Nature::Registry.add_nature(DummyNature.new)
    define('foo', :natures => :dummy).eclipse.options.natures.should == ['MyNature']
  end
  
  
end