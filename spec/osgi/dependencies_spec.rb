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

describe OSGi::Dependencies do
  
  it "should read a dependencies.yml file" do
    write "dependencies.yml", {"foo" => {"dependencies" => ["com:artifact:jar:1.0"], "projects" => ["bar", "foobar"]},
                               "bar" => {"dependencies" => [], "projects" => []},
                               "foobar" => {"dependencies" => [], "projects" => []}}.to_yaml
    foo = define("foo")
    bar = define("bar")
    foobar = define("foobar")
    deps = OSGi::Dependencies.new(foo)
    deps.read
    deps.dependencies.should == ["com:artifact:jar:1.0"]
    deps.projects.should == [bar, foobar]
  end
  
  it "should complain if a project is missing" do
    write "dependencies.yml", {"foo" => {"dependencies" => ["com:artifact:jar:1.0"], "projects" => ["bar", "foobar"]}}.to_yaml
    foo = define("foo")
    bar = define("bar")
    
    deps = OSGi::Dependencies.new(foo)
    lambda { deps.read }.should_not raise_error(RuntimeError, /No such project/)
  end
  
  it "should add the project to the dependencies even if the project is not declared in the dependencies file" do
    write "dependencies.yml", {"foo" => {"dependencies" => ["com:artifact:jar:1.0"], "projects" => ["bar", "foobar"]}}.to_yaml
    foo = define("foo")
    bar = define("bar")
    foobar = define("foobar")
    deps = OSGi::Dependencies.new(foo)
    deps.read
    deps.dependencies.should == ["com:artifact:jar:1.0"]
    deps.projects.should == [bar, foobar]
  end
  
  it "should find the dependencies of each project even if cycles are present" do
    write "dependencies.yml", {"foo" => {"dependencies" => ["com:artifact:jar:1.0"], "projects" => ["bar", "foobar"]},
                               "bar" => {"dependencies" => [], "projects" => ["foo"]},
                               "foobar" => {"dependencies" => [], "projects" => ["bar"]}}.to_yaml
    foo = define("foo")
    bar = define("bar")
    foobar = define("foobar")
    deps = OSGi::Dependencies.new(foo)
    deps.read
    deps.dependencies.should == ["com:artifact:jar:1.0"]
    deps.projects.should == [bar, foobar]
  end
  
  it "should add the dependencies of the projects it depends on to its own" do
    write "dependencies.yml", {"foo" => {"dependencies" => [], "projects" => ["bar"]},
                               "bar" => {"dependencies" => ["com:artifact:jar:1.0"], "projects" => []}}.to_yaml
    foo = define("foo")
    bar = define("bar")
    deps = OSGi::Dependencies.new(foo)
    deps.read
    deps.dependencies.should == ["com:artifact:jar:1.0"]
    deps.projects.should == [bar]
  end
  
  it "should write dependencies for several projects" do
    foo = define("foo")
    bar = define("bar")
    deps = OSGi::Dependencies.new(foo)
    deps.write([foo, "bar"]) {|hash, name|
      case
        when name == "foo"  
          hash["foo"]["projects"] << "bar"
        when name == "bar"
          hash["bar"]["dependencies"] << "com:art:jar:1.0"  
      end
    }
    YAML.load(File.read("dependencies.yml")).should == {"foo"=>{"projects"=>["bar"], "dependencies"=>[]}, "bar"=>{"projects"=>[], "dependencies"=>["com:art:jar:1.0"]}}
  end
end