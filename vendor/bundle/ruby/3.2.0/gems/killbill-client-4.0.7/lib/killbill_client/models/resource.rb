require 'json'

module KillBillClient
  module Model
    class Resource

      attr_reader :clazz,
                  :etag,
                  :session_id,
                  :response

      KILLBILL_API_PREFIX = '/1.0/kb'
      KILLBILL_API_PAGINATION_PREFIX = 'pagination'

      @@attribute_names = {}

      def initialize(hash = nil)
	@uri = nil
        # Make sure we support ActiveSupport::HashWithIndifferentAccess for Kaui
        if hash.respond_to?(:each)
          hash.each do |key, value|
            send("#{Utils.underscore key.to_s}=", value)
          end
        end
      end

      class << self

        def require_multi_tenant_options!(options, msg)
          api_key = options[:api_key] || KillBillClient.api_key
          api_secret = options[:api_secret] || KillBillClient.api_secret
          if api_key.nil? || api_secret.nil?
            raise ArgumentError, msg
          end
        end

        def head(uri, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.head uri, params, options
          from_response clazz, response
        end

        def get(uri, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.get uri, params, options
          from_response clazz, response
        end

        def post(uri, body = nil, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.post uri, body, params, options
          from_response clazz, response
        end

        def put(uri, body = nil, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.put uri, body, params, options
          from_response clazz, response
        end

        def delete(uri, body = nil, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.delete uri, body, params, options
          from_response clazz, response
        end

        # Instantiates a record from an HTTP response, setting the record's
        # response attribute in the process.
        #
        # @return [Resource]
        # @param resource_class [Resource]
        # @param response [Net::HTTPResponse]
        def from_response(resource_class, response)
          case response['Content-Type']
            when nil
              response.body
            when %r{application/pdf}
              response.body
            when %r{text/html}
              response.body
            when %r{text/plain}
              response.body
            when %r{application/octet-stream}
              response.body
            when %r{text/xml}
              if response['location']
                response['location']
              else
                response.body
              end
            when %r{application/json}
              record = from_json resource_class, response.body
              if record.nil?
                record = resource_class.new
                record.uri = response['location']
              end

              session_id = extract_session_id(response)
              record.instance_eval {
                @clazz = resource_class
                @etag = response['ETag']
                @session_id = session_id
                @pagination_max_nb_records = response['X-Killbill-Pagination-MaxNbRecords'].to_i unless response['X-Killbill-Pagination-MaxNbRecords'].nil?
                @pagination_total_nb_records = response['X-Killbill-Pagination-TotalNbRecords'].to_i unless response['X-Killbill-Pagination-TotalNbRecords'].nil?
                @pagination_next_page = response['X-Killbill-Pagination-NextPageUri']
                @response = response
              }
              record
            else
              raise ArgumentError, "#{response['Content-Type']} is not supported by the library"
          end
        end

        # Instantiates a record from a JSON blob.
        #
        # @return [Resource]
        # @param resource_class [Resource]
        # @param json [String]
        # @see from_response
        def from_json(resource_class, json)
          # e.g. DELETE
          return nil if json.nil? or json.size == 0
          data = JSON.parse json

          if data.is_a? Array
            records = Resources.new
            data.each do |data_element|
              if data_element.is_a? Enumerable
                records << instantiate_record_from_json(resource_class, data_element)
              else
                # Value (e.g. String)
                records << data_element
              end
            end
            records
          else
            instantiate_record_from_json(resource_class, data)
          end
        end

        def instantiate_record_from_json(resource_class, data)
          record = resource_class.send :new

          kb_ancestors = resource_class.ancestors.select { |ancestor| !@@attribute_names[ancestor.name].nil? }
          data.each do |name, value|
            name = Utils.underscore name
            attr_desc = nil

            # Allow for inheritance
            kb_ancestors.each do |ancestor|
              attr_desc = @@attribute_names[ancestor.name][name.to_sym]
              break unless attr_desc.nil?
            end

            unless attr_desc.nil?
              type = attr_desc[:type]
              if attr_desc[:cardinality] == :many && !type.nil? && value.is_a?(Array)
                newValue = []
                value.each do |val|
                  if val.is_a?(Hash)
                    newValue << instantiate_record_from_json(type, val)
                  else
                    newValue << val
                  end
                end
                value = newValue
              elsif attr_desc[:cardinality] == :one && !type.nil? && value.is_a?(Hash)
                value = instantiate_record_from_json(type, value)
              end
            end #end unless attr_desc.nil? or data_elem.blank?

            # TODO Be lenient for now to support different API formats
            record.send("#{Utils.underscore name}=", value) rescue nil

          end #end data.each

          record
        end

        def attribute(name)
          send('attr_accessor', name.to_sym)
          attributes = @json_attributes ||= []

          if respond_to?(:json_attributes, true)
            json_attributes.push(name.to_s)
          else
            (class << self; self; end).
              send(:define_method, :json_attributes) { attributes }
            json_attributes.push(name.to_s)
          end
        end

        def has_many(attr_name, type = nil)
          send("attr_accessor", attr_name.to_sym)

          #add it to attribute_names
          @@attribute_names[self.name] ||= {}
          @@attribute_names[self.name][attr_name.to_sym] = {:type => type, :cardinality => :many}
        end

        def has_one(attr_name, type = nil)
          send("attr_accessor", attr_name.to_sym)

          #add it to attribute_names
          @@attribute_names[self.name] ||= {}
          @@attribute_names[self.name][attr_name.to_sym] = {:type => type, :cardinality => :one}
        end

        #hack to cater the api return attributes and javax attributes without editing gen scripts
        #call only after its declared as a instance_method using attr_accessor
        def create_alias(new_name, old_name)
          alias_method new_name.to_sym, old_name.to_sym #getter
          alias_method "#{new_name}=".to_sym, "#{old_name}=".to_sym #setter
        end

        # Extract the session id from a response
        def extract_session_id(response)
          # The Set-Cookie header looks like
          # "set-cookie"=>["JSESSIONID=16; Path=/; HttpOnly", "rememberMe=deleteMe; Path=/; Max-Age=0; Expires=Sat, 17-Aug-2013 23:39:37 GMT"],
          session_cookie = response['set-cookie']
          unless session_cookie.nil?
            session_cookie.split(';').each do |chunk|
              chunk.strip!
              key, value = chunk.split('=')
              return value if key == 'JSESSIONID'
            end
          end
          nil
        end
      end #end self methods

      # Set on create call
      attr_accessor :uri

      def to_hash
        json_hash = {}
        self.class.json_attributes.each do |name|
          value = self.send(name)
          unless value.nil?
            json_hash[Utils.camelize name, :lower] = _to_hash(value)
          end
        end
        json_hash
      end

      def _to_hash(value)
        if value.is_a?(Resource)
          value.to_hash
        elsif value.is_a?(Array)
          value.map { |v| _to_hash(v) }
        else
          value
        end
      end

      def to_json(*args)
        to_hash.to_json(*args)
      end

      def refresh(options = {}, clazz=self.class)
        if @uri
          # Need to decode in case an encoding is in place (e.g. /1.0/kb/security/users/Mad%20Max/roles) , since later on
          # it will be encoded and can cause an undesired result on the call.
          unecoded_uri = URI::DEFAULT_PARSER.unescape(@uri)

          self.class.get unecoded_uri, {}, options, clazz
        else
          self
        end
      end


      def ==(o)
        o.class == self.class && o.hash == hash
      end

      alias_method :eql?, :==

      def hash
        to_hash.hash
      end
    end
  end
end
