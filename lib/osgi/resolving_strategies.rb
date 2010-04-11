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

module OSGi #:nodoc:
  
  # Functions declared on this module are used to select bundles exporting a particular package.
  # Functions must have the signature (package, bundles)
  #   where 
  #     package: the name of the package
  #     bundles: an array of bundles
  #
  module PackageResolvingStrategies
  
    # Default module function that prompts the user to select the bundle(s)
    # he'd like to select as dependencies.
    #
    def prompt(package, bundles)
      bundle = nil
      while (bundle.nil?)
        puts "This package #{package} is exported by all the bundles present.\n" +
              "Choose a bundle amongst those presented or press A to select them all:\n" + bundles.sort! {|a, b| a.version <=> b.version }.
        collect {|b| "\t#{bundles.index(b) +1}. #{b.name} #{b.version}"}.join("\n")
        number = $stdin.gets.chomp
        begin
          return bundles if (number == 'A')
          number = number.to_i
          number -= 1
          bundle = bundles[number] if number >= 0 # no negative indexing here.
          puts "Invalid index" if number < 0
        rescue Exception => e
          puts "Invalid index"
          #do nothing
        end
      end
      [bundle]
    end
    
    # Default module function that selects all the matching bundles to the dependencies.
    # This is the default function.
    #
    def all(package, bundles)
      warn "*** SPLIT PACKAGE: #{package} is exported by <#{bundles.join(", ")}>"
      return bundles
    end  
    
    module_function :prompt, :all
  end
  
  # Functions declared on this module are used to select bundles amongst a list of them, 
  # when requiring bundles through the Require-Bundle header.
  # Functions must have the signature (bundles)
  #   where 
  #     bundles: an array of bundles
  #
  module BundleResolvingStrategies
    #
    # Default strategy:
    # the bundle with the highest version number is returned.
    #
    def latest(bundles)
      bundles.sort {|a, b| a.version <=> b.version}.last
    end

    #
    # The bundle with the lowest version number is returned.
    #
    def oldest(bundles)
      bundles.sort {|a, b| a.version <=> b.version}.first
    end

    # Default module function that prompts the user to select the bundle
    # he'd like to select as dependencies.
    # 
    def prompt(bundles)
      bundle = nil
      while (bundle.nil?)
        puts "Choose a bundle amongst those presented:\n" + bundles.sort! {|a, b| a.version <=> b.version }.
        collect {|b| "\t#{bundles.index(b) +1}. #{b.name} #{b.version}"}.join("\n")
        number = $stdin.gets.chomp
        begin
          number = number.to_i
          number -= 1
          bundle = bundles[number] if number >= 0 # no negative indexing here.
          puts "Invalid index" if number < 0
        rescue Exception => e
          puts "Invalid index"
          #do nothing
        end
      end
      bundle
    end

    module_function :latest, :oldest, :prompt
  end
end