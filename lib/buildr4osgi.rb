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

require 'buildr4osgi/nature'
require 'buildr4osgi/osgi'
require 'buildr4osgi/eclipse'
require 'buildr4osgi/compile'

# Methods defined in Buildr4OSGi are both instance methods (e.g. when included in Project)
# and class methods when invoked like Buildr4OSGi.project_library(SLF4J, "group", "foo", "1.0.0").
module Buildr4OSGi ; extend self ; end
# The Buildfile object (self) has access to all the Buildr4OSGi methods and constants.
class << self ; include Buildr4OSGi ; end
class Object #:nodoc:
  Buildr4OSGi.constants.each do |name|
    const = Buildr4OSGi.const_get(name)
    const_set name, const if const.is_a?(Module)
  end
end

# Project has visibility over everything in the Buildr4OSGi namespace.
# Rename the manifest function first.
# class Buildr::Project
#   include Buildr4OSGi
# end
