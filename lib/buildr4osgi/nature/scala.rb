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
 
module Buildr
  class ScalaNature < DefaultNature
 
    def initialize()
      super(:scala)
      eclipse.natures = ["ch.epfl.lamp.sdt.core.scalanature", "org.eclipse.jdt.core.javanature"] 
      eclipse.builders =  "ch.epfl.lamp.sdt.core.scalabuilder"
      eclipse.classpath_containers =  ["ch.epfl.lamp.sdt.launching.SCALA_CONTAINER", "org.eclipse.jdt.launching.JRE_CONTAINER"]
    end
 
    def applies(project)
      File.exists? project.path_to(:src, :main, :scala)
    end
  end 
 
  Nature::Registry.add_nature(ScalaNature.new, :java)
end