# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013-2017 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/framework'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling zero-touch Google Cloud Debugger support.
    class GoogleStackdriverDebugger < JavaBuildpack::Component::VersionedDependencyComponent

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        download_tar false

        credentials = @application.services.find_service(FILTER)['credentials']
        write_private_key credentials[PRIVATE_KEY_DATA]
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        credentials = @application.services.find_service(FILTER)['credentials']
        java_opts   = @droplet.java_opts

        java_opts
          .add_agentpath(@droplet.sandbox + 'cdbg_java_agent.so')
          .add_system_property('com.google.cdbg.auth.serviceaccount.email', credentials[EMAIL])
          .add_system_property('com.google.cdbg.auth.serviceaccount.enable', true)
          .add_system_property('com.google.cdbg.auth.serviceaccount.p12file', private_key)
          .add_system_property('com.google.cdbg.auth.serviceaccount.projectid', credentials[PROJECT_ID])
          .add_system_property('com.google.cdbg.auth.serviceaccount.projectnumber', credentials[PROJECT_ID])
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        @application.services.one_service? FILTER, EMAIL, PRIVATE_KEY_DATA, PROJECT_ID
      end

      FILTER = /google-stackdriver-debugger/

      EMAIL = 'Email'.freeze

      PRIVATE_KEY_DATA = 'PrivateKeyData'.freeze

      PROJECT_ID = 'ProjectId'.freeze

      private_constant :FILTER, :EMAIL, :PRIVATE_KEY_DATA, :PROJECT_ID

      private

      def private_key
        @droplet.sandbox + 'private-key.p12'
      end

      def write_private_key(private_key_data)
        FileUtils.mkdir_p private_key.parent
        private_key.open(File::CREAT | File::WRONLY) do |f|
          f.write "#{private_key_data}\n"
          f.sync
          f
        end
      end

    end

  end
end
