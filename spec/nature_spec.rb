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

require File.join(File.dirname(__FILE__), '/spec_helpers')


describe Buildr::Nature do
  
  before :all do
    class DummyNature < Buildr::DefaultNature
      def initialize()
        super(:dummy)
      end
    end
    @dummy = DummyNature.new
    class OtherDummyNature < Buildr::DefaultNature
      def initialize()
        super(:otherdummy)
      end
    end
    @otherdummy = OtherDummyNature.new
    class InvalidNature < Buildr::DefaultNature
      def initialize()
        super(:dummy)
      end
    end
    @invalid = InvalidNature.new
  end
  
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
  
  it 'should accept new natures' do
    lambda { Buildr::Nature::Registry.add_nature(@dummy) }.should_not raise_error
  end
  
  it 'should accept new natures to be placed before registered ones' do
    lambda { Buildr::Nature::Registry.add_nature(@otherdummy, :dummy) }.should_not raise_error
    lambda {Buildr::Nature::Registry.all().index(@otherdummy) < 
        Buildr::Nature::Registry.all().index(@otherdummy)}.should be_true
  end
  
  it 'should not accept incorrect objects' do
     lambda { Buildr::Nature::Registry.add_nature(define('uh')) }.should raise_error(RuntimeError, /uh is not a nature!/)
   end
  it 'should not accept duplicate natures' do
    lambda { Buildr::Nature::Registry.add_nature(@invalid) }.should raise_error(RuntimeError, /A nature with the same id is already present/)
  end
  
  it 'should list all available natures' do
    # We also have the Java and Scala natures in there.
    Buildr::Nature::Registry.all().should include(@dummy)
  end
  
  it 'should make natures available' do
    Buildr::Nature::Registry.get(:dummy).should eql(@dummy)
    Buildr::Nature::Registry.get("dummy").should eql(@dummy)
  end
end

describe Buildr::DefaultNature do
  
  before :all do
    class DummyNature < Buildr::DefaultNature
      def initialize()
        super(:dummy)
      end
    end
    @dummy = DummyNature.new
    Buildr::Nature::Registry.add_nature(@dummy)
  end
  
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
  
  it 'should never apply by default' do
    default = Buildr::DefaultNature.new(:somenature)
    default.applies(define('foo')).should eql(false)
  end
  
  it 'should determine project natures from the applies method' do
    class DummyNatureAlwaysApply < Buildr::DefaultNature
      def initialize()
        super(:always)
      end
      def applies(project)
        true # always applies
      end
    end
    always = DummyNatureAlwaysApply.new
    Buildr::Nature::Registry.add_nature(always)
    foo = define('foo')
    foo.applicable_natures.should include(always)
    #By default applies return false.
    foo.applicable_natures.should_not include(@dummy)
  end
  
  it 'should let projects define their natures' do
    foo = define('foo', :natures => :dummy)
    foo.applicable_natures.should include(@dummy)
    bar = define('bar', :natures => [:dummy])
    bar.applicable_natures.should include(@dummy)
  end
  
  it 'should use the parent natures if no nature is defined on this project' do
    dummy = @dummy
    foo = define('foo', :natures => :dummy) do
      bar = define('bar')
      bar.applicable_natures.should include(dummy)
    end
    foo = define('foo2', :natures => :dummy) do
      bar = define('bar', :natures => [])
      bar.applicable_natures.should_not include(dummy)
    end
  end
end