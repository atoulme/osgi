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

require "manifest"
# We will be messing up with .jar files that we will treat just like zip files.
unless (defined?(Zip::ZipFile))
  require "zip/zip"
  require "zip/zipfilesystem"
end

module OSGi
  
  class Container

    # bundles: the bundles of the eclipse instance loaded on startup
    # location: the location of the Eclipse instance
    attr_accessor :bundles, :location

    # Default constructor for an OSGiRegistry
    # 
    # location: the location of the Eclipse instance
    # plugin_locations, default value is ["dropins", "plugins"] 
    # create_bundle_info, default value is true
    def initialize(location, plugin_locations = ["dropins", "plugins"])
      @location = location
      @bundles = []
      plugin_locations.each do |p_loc|
        p_loc_complete = File.join(@location, p_loc)
        warn "Folder #{p_loc_complete} not found!" if !File.exists? p_loc_complete 
        parse(p_loc_complete) if File.exists? p_loc_complete
      end
    end

    # Parses the directory and grabs the plugins, adding the created bundle objects to @bundles.
    def parse(dir)
      Dir.open(dir) do |plugins|
        plugins.entries.each do |plugin|
          absolute_plugin_path = "#{plugins.path}#{File::SEPARATOR}#{plugin}"
          if (/.*\.jar$/.match(plugin)) 
            zipfile = Zip::ZipFile.open(absolute_plugin_path)
            entry =  zipfile.find_entry("META-INF/MANIFEST.MF")
            if (entry != nil)
              manifest = Manifest.read(zipfile.read("META-INF/MANIFEST.MF"))
              @bundles << Bundle.fromManifest(manifest, absolute_plugin_path) 
            end
            zipfile.close
          else
            # take care of the folder
            if (File.directory?(absolute_plugin_path) && !(plugin == "." || plugin == ".."))
              if (!File.exists? ["#{absolute_plugin_path}", "META-INF", "MANIFEST.MF"].join(File::SEPARATOR))
                #recursive approach: we have a folder wih no MANIFEST.MF, we should look into it.
                parse(absolute_plugin_path)
              else
                next if File.exists? "#{absolute_plugin_path}/feature.xml" # avoid parsing features.
                begin
                  manifest = Manifest.read((file = File.open("#{absolute_plugin_path}/META-INF/MANIFEST.MF")).read)
                rescue
                  file.close
                end
                @bundles << Bundle.fromManifest(manifest, absolute_plugin_path)
              end
            end
          end
        end
      end
    end
    
    # Return the list of bundles that match the criteria passed as arguments
    def find(criteria = {:name => "", :version =>""})
      selected = bundles
      if (criteria[:name])
        selected = selected.select {|b| b.name == criteria[:name]}
      end
      if (criteria[:version])
        selected = selected.select {|b| b.version == criteria[:version]}
      end
      selected
    end

  end

end