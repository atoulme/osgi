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

module OSGi
#
# A class to read dependencies.yml, and get a flat array of projects and dependencies for a project.
#
class Dependencies
  
  attr_accessor :dependencies, :projects
  
  def initialize(project = nil)
    @project = project
  end
    
  def read() 
    base_dir = find_root(@project).base_dir
    @dependencies = []
    @projects = []
    @deps_yml = {}
    return unless File.exists? File.join(base_dir, "dependencies.yml")
    @deps_yml =YAML.load(File.read(File.join(base_dir, "dependencies.yml")))
    return if @deps_yml[@project.name].nil? || @deps_yml[@project.name]["dependencies"].nil?
    _read(@project, false)
    @dependencies = @dependencies.flatten.compact.uniq
    return @dependencies, @projects
  end
  
  def write(projects)
    base_dir = find_root(@project).base_dir
    written_dependencies = YAML.load(File.read(File.join(base_dir, "dependencies.yml"))) if File.exists? File.join(base_dir, "dependencies.yml")
    written_dependencies ||= {}
    written_dependencies.extend SortedHash
    projects.each {|p|
      p = p.name if p.is_a?(Project) 
      written_dependencies[p] ||= {}
      written_dependencies[p].extend SortedHash
      written_dependencies[p]["dependencies"] ||= []
      written_dependencies[p]["projects"] ||= []
      yield written_dependencies, p
      written_dependencies[p]["dependencies"].sort!
      written_dependencies[p]["projects"].sort!
    }
    Buildr::write File.join(base_dir, "dependencies.yml"), written_dependencies.to_yaml
  end
  
  private
  
  def _read(project, add_project = true)
    projects << project if add_project
    return unless @deps_yml[project.name] && @deps_yml[project.name]["dependencies"]
    @dependencies |= @deps_yml[project.name]["dependencies"]
    @deps_yml[project.name]["projects"].each {|p| subp = Buildr::project(p) ; _read(subp) unless (projects.include?(subp) || subp == @project)}
  end
  
  def find_root(project)
    project.parent.nil? ? project : project.parent
  end
  
  # Copy/pasted from here: http://snippets.dzone.com/posts/show/5811
  # no author information though.
  module SortedHash
    
    # Replacing the to_yaml function so it'll serialize hashes sorted (by their keys)
    #
    # Original function is in /usr/lib/ruby/1.8/yaml/rubytypes.rb
    def to_yaml( opts = {} )
      YAML::quick_emit( object_id, opts ) do |out|
        out.map( taguri, to_yaml_style ) do |map|
          sort.each do |k, v|   # <-- here's my addition (the 'sort')
            map.add( k, v )
          end
        end
      end
    end
  end
end

end