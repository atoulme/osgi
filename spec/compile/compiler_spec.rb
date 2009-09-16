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

describe Buildr4OSGi::CompilerSupport::OSGiC do
  describe "should compile a Java project just in the same way javac does" do  
    javac_spec = File.read(File.join(File.dirname(__FILE__), "..", "..", "buildr", "spec", "java", "compiler_spec.rb"))
    javac_spec = javac_spec.match(Regexp.escape("require File.join(File.dirname(__FILE__), '../spec_helpers')\n")).post_match
    javac_spec.gsub!("javac", "osgic")
    javac_spec.gsub!("nowarn", "warn:none")
    eval(javac_spec)
  end
  
  # Redirect the java error ouput, yielding so you can do something while it is
  # and returning the content of the error buffer.
  #
  def redirect_java_err
    byteArray = Rjb::import('java.io.ByteArrayOutputStream')
    printStream = Rjb::import('java.io.PrintStream')
    err = byteArray.new()
    Rjb::import('java.lang.System').err = printStream.new(err)
    yield
    err.toString
  end
  
  it "should not issue warnings for type casting when warnings are set to warn:none" do
    write "src/main/java/Main.java", "import java.util.List; public class Main {public List get() {return null;}}"
    foo = define("foo") {
      compile.options.source = "1.5"
      compile.options.target = "1.5"
    }
    redirect_java_err { foo.compile.invoke }.should_not match(/WARNING/)
  end
  
  it "should not issue warnings for type casting when warnings are set to warn:none" do
    write "src/main/java/Main.java", "import java.util.List; public class Main {public List get() {return null;}}"
    foo = define("foo") {
      compile.options.source = "1.5"
      compile.options.target = "1.5"
      compile.options.warnings = true
    }
    redirect_java_err { foo.compile.invoke }.should match(/WARNING/)
  end
  
  
end


