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

module Buildr4OSGi

  class Category

    attr_accessor :features, :name, :label, :description 

    def initialize()
      @features = []
    end

  end

  module SiteWriter

    attr_accessor :description, :description_url, :categories

    # :nodoc:
    # When this module extends an object
    # the categories are initialized as empty arrays.
    #
    def SiteWriter.extend_object(obj)
      super(obj)
      obj.categories = []
    end
    
    #
    # http://help.eclipse.org/ganymede/index.jsp?topic=/org.eclipse.platform.doc.isv/reference/misc/update_sitemap.html
    #
    #<site pack200="false">
    #  <description url="http://www.example.com/DescriptionOfSite">Some description</description>
    #  <category-def name="some.id" label="Human readable label">
    #    <description>Some description</description>
    #  </category-def>
    #  <feature id="feature.id" version="2.0.3" url="features/myfeature.jar" patch="false">
    #    <category name="some.id"/>
    #  </feature>
    #</site>
    #
    def writeSiteXml()
      x = Builder::XmlMarkup.new(:target => out = "", :indent => 1)
      x.instruct!
      x.site(:pack200 => "false") {
        x.description(description, :url => description_url) if (description || description_url)
        for category in categories
          x.tag!("category-def", :name => category.name, :label => category.label) {
            x.description category.description if category.description
          }
        end

        f2c = {}
        categories.each do |category|
          for f in category.features
            f2c[f] ||= []
            f2c[f] << category
          end
        end
        
        f2c.each_pair { |feature, categories|
          x.feature(:id => feature.id, :version => feature.version, :url => "features/#{feature.id}_#{feature.version}.jar", :patch => false) {
            for category in categories
              x.category(:name => category.name)
            end
          }
        }
      }
    end  
  end
end
