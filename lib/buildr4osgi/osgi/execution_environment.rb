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
  
  # The notion of profile in OSGi refers to the execution environment: SDK, loaded libraries in LD_LIBRARY_PATH.
  # A set of default execution environments is defined by the OSGi specifications.
  class ExecutionEnvironment
    
    attr_reader :name, :description, :packages
    
    def initialize(name, description, packages)
      @name = name
      @description = description
      @packages = packages.is_a?(Array) ? packages : [packages]
      @packages.freeze
      freeze
    end
    
  end
  
  # No profile.
  NONE = ExecutionEnvironment.new("None", "None", [])
  
  # The standard CDC-1.0/Foundation-1.0 profile
  CDC10FOUNDATION10 = ExecutionEnvironment.new("CDC-1.0/Foundation-1.0", "Equal to J2ME Foundation Profile", ["javax.microedition.io"])
  
  # The standard CDC-1.0/Foundation-1.1 profile
  CDC10FOUNDATION11 = ExecutionEnvironment.new("CDC-1.0/Foundation-1.1", "Equal to J2ME Foundation Profile", ["javax.microedition.io","javax.microedition.pki",
    "javax.security.auth.x500"])
    
  # The standard J2SE-1.2 profile
  J2SE12 = ExecutionEnvironment.new("J2SE-1.2", "Java 2 Platform, Standard Edition 1.2", %w{javax.accessibility javax.swing javax.swing.border javax.swing.colorchooser javax.swing.event javax.swing.filechooser 
    javax.swing.plaf javax.swing.plaf.basic javax.swing.plaf.metal javax.swing.plaf.multi javax.swing.table javax.swing.text javax.swing.text.html 
    javax.swing.text.html.parser javax.swing.text.rtf javax.swing.tree javax.swing.undo org.omg.CORBA org.omg.CORBA.DynAnyPackage org.omg.CORBA.ORBPackage 
    org.omg.CORBA.portable org.omg.CORBA.TypeCodePackage org.omg.CosNaming org.omg.CosNaming.NamingContextPackage})
  
  # The standard J2SE-1.3 profile
  J2SE13 = ExecutionEnvironment.new("J2SE-1.3", "Java 2 Platform, Standard Edition 1.3", %w{javax.accessibility javax.naming javax.naming.directory javax.naming.event javax.naming.ldap
     javax.naming.spi javax.rmi javax.rmi.CORBA javax.sound.midi javax.sound.midi.spi javax.sound.sampled javax.sound.sampled.spi javax.swing javax.swing.border
     javax.swing.colorchooser javax.swing.event javax.swing.filechooser javax.swing.plaf javax.swing.plaf.basic javax.swing.plaf.metal javax.swing.plaf.multi
     javax.swing.table javax.swing.text javax.swing.text.html javax.swing.text.html.parser javax.swing.text.rtf javax.swing.tree javax.swing.undo javax.transaction
     org.omg.CORBA org.omg.CORBA_2_3 org.omg.CORBA_2_3.portable org.omg.CORBA.DynAnyPackage org.omg.CORBA.ORBPackage org.omg.CORBA.portable
     org.omg.CORBA.TypeCodePackage org.omg.CosNaming org.omg.CosNaming.NamingContextPackage org.omg.SendingContext org.omg.stub.java.rmi})
     
  # The standard J2SE-1.4 profile
  J2SE14 = ExecutionEnvironment.new("J2SE-1.4", "Java 2 Platform, Standard Edition 1.4", %w{javax.accessibility javax.crypto javax.crypto.interfaces javax.crypto.spec javax.imageio 
    javax.imageio.event javax.imageio.metadata javax.imageio.plugins.jpeg javax.imageio.spi javax.imageio.stream javax.naming javax.naming.directory javax.naming.event 
    javax.naming.ldap javax.naming.spi javax.net javax.net.ssl javax.print javax.print.attribute javax.print.attribute.standard javax.print.event javax.rmi 
    javax.rmi.CORBA javax.security.auth javax.security.auth.callback javax.security.auth.kerberos javax.security.auth.login javax.security.auth.spi 
    javax.security.auth.x500 javax.security.cert javax.sound.midi javax.sound.midi.spi javax.sound.sampled javax.sound.sampled.spi javax.sql javax.swing 
    javax.swing.border javax.swing.colorchooser javax.swing.event javax.swing.filechooser javax.swing.plaf javax.swing.plaf.basic javax.swing.plaf.metal 
    javax.swing.plaf.multi javax.swing.table javax.swing.text javax.swing.text.html javax.swing.text.html.parser javax.swing.text.rtf javax.swing.tree 
    javax.swing.undo javax.transaction javax.transaction.xa javax.xml.parsers javax.xml.transform javax.xml.transform.dom javax.xml.transform.sax 
    javax.xml.transform.stream org.ietf.jgss org.omg.CORBA org.omg.CORBA_2_3 org.omg.CORBA_2_3.portable org.omg.CORBA.DynAnyPackage org.omg.CORBA.ORBPackage 
    org.omg.CORBA.portable org.omg.CORBA.TypeCodePackage org.omg.CosNaming org.omg.CosNaming.NamingContextExtPackage org.omg.CosNaming.NamingContextPackage 
    org.omg.Dynamic org.omg.DynamicAny org.omg.DynamicAny.DynAnyFactoryPackage org.omg.DynamicAny.DynAnyPackage org.omg.IOP org.omg.IOP.CodecFactoryPackage 
    org.omg.IOP.CodecPackage org.omg.Messaging org.omg.PortableInterceptor org.omg.PortableInterceptor.ORBInitInfoPackage org.omg.PortableServer
    org.omg.PortableServer.CurrentPackage org.omg.PortableServer.POAManagerPackage org.omg.PortableServer.POAPackage org.omg.PortableServer.portable 
    org.omg.PortableServer.ServantLocatorPackage org.omg.SendingContext org.omg.stub.java.rmi org.w3c.dom org.w3c.dom.css org.w3c.dom.events 
    org.w3c.dom.html org.w3c.dom.stylesheets org.w3c.dom.views org.xml.sax org.xml.sax.ext org.xml.sax.helpers})
  
  # The standard J2SE-1.5 profile
  J2SE15 = ExecutionEnvironment.new("J2SE-1.5", "Java 2 Platform, Standard Edition 5.0", %w{javax.accessibility javax.activity javax.crypto javax.crypto.interfaces 
    javax.crypto.spec javax.imageio javax.imageio.event 
    javax.imageio.metadata javax.imageio.plugins.bmp javax.imageio.plugins.jpeg javax.imageio.spi javax.imageio.stream javax.management javax.management.loading 
    javax.management.modelmbean javax.management.monitor javax.management.openmbean javax.management.relation javax.management.remote javax.management.remote.rmi 
    javax.management.timer javax.naming javax.naming.directory javax.naming.event javax.naming.ldap javax.naming.spi javax.net javax.net.ssl javax.print 
    javax.print.attribute javax.print.attribute.standard javax.print.event javax.rmi javax.rmi.CORBA javax.rmi.ssl javax.security.auth javax.security.auth.callback 
    javax.security.auth.kerberos javax.security.auth.login javax.security.auth.spi javax.security.auth.x500 javax.security.cert javax.security.sasl javax.sound.midi 
    javax.sound.midi.spi javax.sound.sampled javax.sound.sampled.spi javax.sql javax.sql.rowset javax.sql.rowset.serial javax.sql.rowset.spi javax.swing 
    javax.swing.border javax.swing.colorchooser javax.swing.event javax.swing.filechooser javax.swing.plaf javax.swing.plaf.basic javax.swing.plaf.metal 
    javax.swing.plaf.multi javax.swing.plaf.synth javax.swing.table javax.swing.text javax.swing.text.html javax.swing.text.html.parser javax.swing.text.rtf 
    javax.swing.tree javax.swing.undo javax.transaction javax.transaction.xa javax.xml javax.xml.datatype javax.xml.namespace javax.xml.parsers javax.xml.transform 
    javax.xml.transform.dom javax.xml.transform.sax javax.xml.transform.stream javax.xml.validation javax.xml.xpath org.ietf.jgss org.omg.CORBA org.omg.CORBA_2_3 
    org.omg.CORBA_2_3.portable org.omg.CORBA.DynAnyPackage org.omg.CORBA.ORBPackage org.omg.CORBA.portable org.omg.CORBA.TypeCodePackage org.omg.CosNaming 
    org.omg.CosNaming.NamingContextExtPackage org.omg.CosNaming.NamingContextPackage org.omg.Dynamic org.omg.DynamicAny org.omg.DynamicAny.DynAnyFactoryPackage 
    org.omg.DynamicAny.DynAnyPackage org.omg.IOP org.omg.IOP.CodecFactoryPackage org.omg.IOP.CodecPackage org.omg.Messaging org.omg.PortableInterceptor 
    org.omg.PortableInterceptor.ORBInitInfoPackage org.omg.PortableServer org.omg.PortableServer.CurrentPackage org.omg.PortableServer.POAManagerPackage 
    org.omg.PortableServer.POAPackage org.omg.PortableServer.portable org.omg.PortableServer.ServantLocatorPackage org.omg.SendingContext org.omg.stub.java.rmi 
    org.w3c.dom org.w3c.dom.bootstrap org.w3c.dom.css org.w3c.dom.events org.w3c.dom.html org.w3c.dom.ls org.w3c.dom.ranges org.w3c.dom.stylesheets 
    org.w3c.dom.traversal org.w3c.dom.views org.xml.sax org.xml.sax.ext org.xml.sax.helpers})
  
  # The standard JavaSE-1.6 profile
  JAVASE16 = ExecutionEnvironment.new("JavaSE-1.6", "Java Platform, Standard Edition 6.0", %w{javax.accessibility javax.activation javax.activity 
    javax.annotation javax.annotation.processing javax.crypto javax.crypto.interfaces 
    javax.crypto.spec javax.imageio javax.imageio.event javax.imageio.metadata javax.imageio.plugins.bmp javax.imageio.plugins.jpeg javax.imageio.spi 
    javax.imageio.stream javax.jws javax.jws.soap javax.lang.model javax.lang.model.element javax.lang.model.type javax.lang.model.util javax.management 
    javax.management.loading javax.management.modelmbean javax.management.monitor javax.management.openmbean javax.management.relation javax.management.remote 
    javax.management.remote.rmi javax.management.timer javax.naming javax.naming.directory javax.naming.event javax.naming.ldap javax.naming.spi javax.net 
    javax.net.ssl javax.print javax.print.attribute javax.print.attribute.standard javax.print.event javax.rmi javax.rmi.CORBA javax.rmi.ssl javax.script 
    javax.security.auth javax.security.auth.callback javax.security.auth.kerberos javax.security.auth.login javax.security.auth.spi javax.security.auth.x500 
    javax.security.cert javax.security.sasl javax.sound.midi javax.sound.midi.spi javax.sound.sampled javax.sound.sampled.spi javax.sql javax.sql.rowset 
    javax.sql.rowset.serial javax.sql.rowset.spi javax.swing javax.swing.border javax.swing.colorchooser javax.swing.event javax.swing.filechooser 
    javax.swing.plaf javax.swing.plaf.basic javax.swing.plaf.metal javax.swing.plaf.multi javax.swing.plaf.synth javax.swing.table javax.swing.text 
    javax.swing.text.html javax.swing.text.html.parser javax.swing.text.rtf javax.swing.tree javax.swing.undo javax.tools javax.transaction 
    javax.transaction.xa javax.xml javax.xml.bind javax.xml.bind.annotation javax.xml.bind.annotation.adapters javax.xml.bind.attachment 
    javax.xml.bind.helpers javax.xml.bind.util javax.xml.crypto javax.xml.crypto.dom javax.xml.crypto.dsig javax.xml.crypto.dsig.dom 
    javax.xml.crypto.dsig.keyinfo javax.xml.crypto.dsig.spec javax.xml.datatype javax.xml.namespace javax.xml.parsers javax.xml.soap javax.xml.stream 
    javax.xml.stream.events javax.xml.stream.util javax.xml.transform javax.xml.transform.dom javax.xml.transform.sax javax.xml.transform.stax 
    javax.xml.transform.stream javax.xml.validation javax.xml.ws javax.xml.ws.handler javax.xml.ws.handler.soap javax.xml.ws.http javax.xml.ws.soap 
    javax.xml.ws.spi javax.xml.xpath org.ietf.jgss org.omg.CORBA org.omg.CORBA_2_3 org.omg.CORBA_2_3.portable org.omg.CORBA.DynAnyPackage 
    org.omg.CORBA.ORBPackage org.omg.CORBA.portable org.omg.CORBA.TypeCodePackage org.omg.CosNaming org.omg.CosNaming.NamingContextExtPackage 
    org.omg.CosNaming.NamingContextPackage org.omg.Dynamic org.omg.DynamicAny org.omg.DynamicAny.DynAnyFactoryPackage org.omg.DynamicAny.DynAnyPackage 
    org.omg.IOP org.omg.IOP.CodecFactoryPackage org.omg.IOP.CodecPackage org.omg.Messaging org.omg.PortableInterceptor 
    org.omg.PortableInterceptor.ORBInitInfoPackage org.omg.PortableServer org.omg.PortableServer.CurrentPackage org.omg.PortableServer.POAManagerPackage 
    org.omg.PortableServer.POAPackage org.omg.PortableServer.portable org.omg.PortableServer.ServantLocatorPackage org.omg.SendingContext 
    org.omg.stub.java.rmi org.w3c.dom org.w3c.dom.bootstrap org.w3c.dom.css org.w3c.dom.events org.w3c.dom.html org.w3c.dom.ls org.w3c.dom.ranges 
    org.w3c.dom.stylesheets org.w3c.dom.traversal org.w3c.dom.views org.xml.sax org.xml.sax.ext org.xml.sax.helpers})
    
  JAVASE17 = ExecutionEnvironment.new("JavaSE-1.7", "Java SE 1.7.x (early access)", %w{javax.accessibility javax.activation javax.activity javax.annotation javax.annotation.processing 
    javax.crypto javax.crypto.interfaces javax.crypto.spec javax.imageio javax.imageio.event javax.imageio.metadata javax.imageio.plugins.bmp 
    javax.imageio.plugins.jpeg javax.imageio.spi javax.imageio.stream javax.jws javax.jws.soap javax.lang.model javax.lang.model.element javax.lang.model.type 
    javax.lang.model.util javax.management javax.management.loading javax.management.modelmbean javax.management.monitor javax.management.openmbean 
    javax.management.relation javax.management.remote javax.management.remote.rmi javax.management.timer javax.naming javax.naming.directory javax.naming.event 
    javax.naming.ldap javax.naming.spi javax.net javax.net.ssl javax.print javax.print.attribute javax.print.attribute.standard javax.print.event javax.rmi 
    javax.rmi.CORBA javax.rmi.ssl javax.script javax.security.auth javax.security.auth.callback javax.security.auth.kerberos javax.security.auth.login 
    javax.security.auth.spi javax.security.auth.x500 javax.security.cert javax.security.sasl javax.sound.midi javax.sound.midi.spi javax.sound.sampled 
    javax.sound.sampled.spi javax.sql javax.sql.rowset javax.sql.rowset.serial javax.sql.rowset.spi javax.swing javax.swing.border javax.swing.colorchooser 
    javax.swing.event javax.swing.filechooser javax.swing.plaf javax.swing.plaf.basic javax.swing.plaf.metal javax.swing.plaf.multi javax.swing.plaf.synth 
    javax.swing.table javax.swing.text javax.swing.text.html javax.swing.text.html.parser javax.swing.text.rtf javax.swing.tree javax.swing.undo javax.tools 
    javax.transaction javax.transaction.xa javax.xml javax.xml.bind javax.xml.bind.annotation javax.xml.bind.annotation.adapters javax.xml.bind.attachment 
    javax.xml.bind.helpers javax.xml.bind.util javax.xml.crypto javax.xml.crypto.dom javax.xml.crypto.dsig javax.xml.crypto.dsig.dom javax.xml.crypto.dsig.keyinfo 
    javax.xml.crypto.dsig.spec javax.xml.datatype javax.xml.namespace javax.xml.parsers javax.xml.soap javax.xml.stream javax.xml.stream.events javax.xml.stream.util 
    javax.xml.transform javax.xml.transform.dom javax.xml.transform.sax javax.xml.transform.stax javax.xml.transform.stream javax.xml.validation javax.xml.ws 
    javax.xml.ws.handler javax.xml.ws.handler.soap javax.xml.ws.http javax.xml.ws.soap javax.xml.ws.spi javax.xml.xpath org.ietf.jgss org.omg.CORBA org.omg.CORBA_2_3 
    org.omg.CORBA_2_3.portable org.omg.CORBA.DynAnyPackage org.omg.CORBA.ORBPackage org.omg.CORBA.portable org.omg.CORBA.TypeCodePackage org.omg.CosNaming 
    org.omg.CosNaming.NamingContextExtPackage org.omg.CosNaming.NamingContextPackage org.omg.Dynamic org.omg.DynamicAny org.omg.DynamicAny.DynAnyFactoryPackage 
    org.omg.DynamicAny.DynAnyPackage org.omg.IOP org.omg.IOP.CodecFactoryPackage org.omg.IOP.CodecPackage org.omg.Messaging org.omg.PortableInterceptor 
    org.omg.PortableInterceptor.ORBInitInfoPackage org.omg.PortableServer org.omg.PortableServer.CurrentPackage org.omg.PortableServer.POAManagerPackage 
    org.omg.PortableServer.POAPackage org.omg.PortableServer.portable org.omg.PortableServer.ServantLocatorPackage org.omg.SendingContext org.omg.stub.java.rmi 
    org.w3c.dom org.w3c.dom.bootstrap org.w3c.dom.css org.w3c.dom.events org.w3c.dom.html org.w3c.dom.ls org.w3c.dom.ranges org.w3c.dom.stylesheets 
    org.w3c.dom.traversal org.w3c.dom.views org.xml.sax org.xml.sax.ext org.xml.sax.helpers})
  
  OSGIMINIMUM10 = ExecutionEnvironment.new("OSGi/Minimum-1.0", "OSGi EE that is a minimal set that allows the implementation of an OSGi Framework", [])
  OSGIMINIMUM11 = ExecutionEnvironment.new("OSGi/Minimum-1.1", "OSGi EE that is a minimal set that allows the implementation of an OSGi Framework", [])
  OSGIMINIMUM12 = ExecutionEnvironment.new("OSGi/Minimum-1.2", "OSGi EE that is a minimal set that allows the implementation of an OSGi Framework", [])
  
  # The execution environment configuration class
  # represents how to dispose of execution environments.
  # The default execution environments are initialized in the constructor.
  #
  class ExecutionEnvironmentConfiguration
    
    attr_accessor :extra_packages, :execution_environment
    
    # Constructor
    def initialize
      @extra_packages = []
      @available_ee = {}
      
      register_execution_environment(NONE)
      register_execution_environment(CDC10FOUNDATION10)
      register_execution_environment(CDC10FOUNDATION11)
      register_execution_environment(J2SE12)
      register_execution_environment(J2SE13)
      register_execution_environment(J2SE14)
      register_execution_environment(J2SE15)
      register_execution_environment(JAVASE16)
      register_execution_environment(JAVASE17)
      register_execution_environment(OSGIMINIMUM10)
      register_execution_environment(OSGIMINIMUM11)
      register_execution_environment(OSGIMINIMUM12)
      
      @execution_environment = JAVASE16.name
    end
    
    #
    # Returns the current execution environment.
    # By default we return JavaSE-1.6
    #
    def current_execution_environment
      @available_ee[@execution_environment]
    end
    
    # Registers an execution enviroment in the configuration.
    # This method should be used to register additional execution environments using an extension.
    # 
    def register_execution_environment(ee)
      raise "Cannot register this execution environment" unless ee.is_a? ExecutionEnvironment
      available_ee[ee.name] = ee
    end
    
    protected
      
    attr_accessor :available_ee
    
  end
end