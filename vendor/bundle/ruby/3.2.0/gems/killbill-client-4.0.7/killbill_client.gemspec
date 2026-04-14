#
# Copyright 2010-2013 Ning, Inc.
#
# Ning licenses this file to you under the Apache License, version 2.0
# (the "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.
#

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'killbill_client/version'

Gem::Specification.new do |s|
  s.name        = 'killbill-client'
  s.version     = KillBillClient::VERSION
  s.summary     = 'Kill Bill client library.'
  s.description = 'An API client library for Kill Bill.'

  s.required_ruby_version = '>= 1.8.6'

  s.license = 'Apache-2.0'

  s.author   = 'Killbill core team'
  s.email    = 'killbilling-users@googlegroups.com'
  s.homepage = 'http://www.killbilling.org'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.bindir        = 'bin'
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.rdoc_options << '--exclude' << '.'

  s.add_development_dependency 'gem-release', '~> 2.2'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.4'
end
