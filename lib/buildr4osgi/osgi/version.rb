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
  
  #
  # A class to represent OSGi versions.
  #
  class Version

    attr_accessor :major, :minor, :tiny, :qualifier

    def initialize(string) #:nodoc:
      digits = string.gsub(/\"/, '').split(".")
      @major = digits[0]
      @minor = digits[1]
      @tiny = digits[2]
      @qualifier = digits[3]
      raise "Invalid version: " + self.to_s if @major == ""
      raise "Invalid version: " + self.to_s if @minor == "" && (!@tiny != "" || !@qualifier != "")
      raise "Invalid version: " + self.to_s if @tiny == "" && !@qualifier != ""
    end


    def to_s #:nodoc:
      str = [major]
      str << minor if minor
      str << tiny if minor && tiny
      str << qualifier if minor && tiny && qualifier
      str.compact.join(".")
    end

    def <=>(other) #:nodoc:
      if other.is_a? String
        other = Version.new(other)
      elsif other.nil?
        return 1
      end

      [:major, :minor, :tiny, :qualifier].each do |digit|
        return 0 if send(digit).nil? 

        comparison = send(digit) <=> other.send(digit)
        if comparison != 0
          return comparison
        end

      end
      return 0
    end

    def <(other) #:nodoc:
      (self.<=>(other)) == -1
    end

    def >(other) #:nodoc:
      (self.<=>(other)) == 1
    end

    def ==(other) #:nodoc:
      (self.<=>(other)) == 0
    end

    def <=(other) #:nodoc:
      (self.==(other)) || (self.<(other))
    end

    def >=(other) #:nodoc:
      (self.==(other)) || (self.>(other))
    end
  end

  class VersionRange #:nodoc:

    attr_accessor :min, :max, :min_inclusive, :max_inclusive, :max_infinite

    # Parses a string into a VersionRange.
    # Returns false if the string could not be parsed.
    #
    def self.parse(string, max_infinite = false)
      return string if string.is_a?(VersionRange)
      if !string.nil? && (match = string.match /\s*([\[|\(])([0-9|\.]*),([0-9|\.]*)([\]|\)])/)
        range = VersionRange.new
        range.min = Version.new(match[2])
        range.max = Version.new(match[3])
        range.min_inclusive = match[1] == '['
        range.max_inclusive = match[4] == ']'
        range
      elsif (!string.nil? && max_infinite  && string.match(/[0-9|\.]*/))
        range = VersionRange.new
        range.min = Version.new(string)
        range.max = nil
        range.min_inclusive = true
        range.max_infinite = true
        range
      else
        false
      end
    end

    def to_s #:nodoc:
      "#{ min_inclusive ? '[' : '('}#{min},#{max_infinite ? "infinite" : max}#{max_inclusive ? ']' : ')'}"
    end

    # Returns true if the version is in the range of this VersionRange object.
    # Uses OSGi versioning rules to determine if the version is in range.
    #
    def in_range(version)
      return in_range(version.min) if version.is_a?(VersionRange)
        
      result = min_inclusive ? min <= version : min < version
      if (!max_infinite)
        result &= max_inclusive ? max >= version : max > version
      end
      result
    end
  end
  
end