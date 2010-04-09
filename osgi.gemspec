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


Gem::Specification.new do |spec|
  spec.name           = 'osgi'
  spec.version        = '0.0.1'
  spec.author         = 'Antoine Toulme'
  spec.email          = "antoine@lunar-ocean.com"
  spec.homepage       = "http://github.com/atoulme/osgi"
  spec.summary        = "An implementation of the OSGi framework in Ruby"
  spec.description    = <<-TEXT
The OSGi framework offers an unique way for Java bundles to communicate and depend on each other.
This implementation of the OSGi framework is supposed to represent the framework as it should be in Ruby.
TEXT
  spec.files          = Dir['{doc,etc,lib,rakelib,spec}/**/*', '*.{gemspec,buildfile}'] +
                        ['LICENSE', 'NOTICE', 'README.rdoc', 'Rakefile']
  spec.require_paths  = ['lib']
  spec.has_rdoc         = true
  spec.extra_rdoc_files = 'README.rdoc', 'LICENSE', 'NOTICE'
  spec.rdoc_options     = '--title', 'OSGi', '--main', 'README.rdoc',
                          '--webcvs', 'http://github.com/atoulme/osgi'
  spec.add_dependency("manifest", "= 0.0.8")
end