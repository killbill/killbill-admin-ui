require 'cgi'
require 'net/https'
require 'json'

module KillBillClient
  class API
    module Net
      module HTTPAdapter
        # A hash of Net::HTTP settings configured before the request.
        #
        # @return [Hash]
        def net_http
          @net_http ||= {}
        end

        # Used to store any Net::HTTP settings.
        #
        # @example
        #   KillBillClient::API.net_http = {
        #     :verify_mode => OpenSSL::SSL::VERIFY_PEER,
        #     :ca_path     => "/etc/ssl/certs",
        #     :ca_file     => "/opt/local/share/curl/curl-ca-bundle.crt"
        #   }
        attr_writer :net_http

        private

        RE_PATH = /(\/1.0\/kb(?:\/\w+){1,2}\/)\w+-\w+-\w+-\w+-\w+(\/\w+)*/

        METHODS = {
            :head => ::Net::HTTP::Head,
            :get => ::Net::HTTP::Get,
            :post => ::Net::HTTP::Post,
            :put => ::Net::HTTP::Put,
            :delete => ::Net::HTTP::Delete
        }

        def build_uri(relative_uri, options)
          # Split the URI into path and query parts
          uri_parts = relative_uri.split('?', 2)
          path_part = uri_parts[0]
          query_part = uri_parts[1]
          
          # Check if this is an absolute URI (has scheme) by looking for protocol pattern
          is_absolute_uri = path_part.match?(/\A[a-z][a-z0-9+.-]*:\/\//i)
          
          if is_absolute_uri
            # This is an absolute URI, parse it carefully
            begin
              # Parse the URI components manually to handle spaces properly
              if path_part.match(/\A([a-z][a-z0-9+.-]*):\/\/([^\/]+)(\/.*)?/i)
                scheme = $1
                authority = $2  # host:port
                path = $3 || '/'
                
                # Encode only the path segments, not the scheme or authority
                if path && path != '/'
                  path_segments = path.split('/')
                  encoded_segments = path_segments.map do |segment|
                    # Skip encoding if the segment is already encoded (contains %XX patterns)
                    if segment.match?(/%[0-9A-Fa-f]{2}/)
                      segment
                    else
                      unsafe_regex = /[^a-zA-Z0-9\-_.!~*'()]/
                      if unsafe_regex.match?(segment)
                        CGI.escape(segment).gsub('+', '%20')
                      else
                        segment
                      end
                    end
                  end
                  encoded_path = encoded_segments.join('/')
                else
                  encoded_path = path
                end
                
                encoded_relative_uri = "#{scheme}://#{authority}#{encoded_path}"
                encoded_relative_uri += "?#{query_part}" if query_part
              else
                # Fallback: treat as relative if parsing fails
                is_absolute_uri = false
              end
            rescue
              # Fallback: treat as relative if any error occurs
              is_absolute_uri = false
            end
          end
          
          unless is_absolute_uri
            # This is a relative URI, encode path segments individually
            path_segments = path_part.split('/')
            encoded_segments = path_segments.map do |segment|
              # Skip encoding if the segment is already encoded (contains %XX patterns)
              if segment.match?(/%[0-9A-Fa-f]{2}/)
                segment
              else
                # Only encode segments that contain unsafe characters
                unsafe_regex = /[^a-zA-Z0-9\-_.!~*'()]/
                if unsafe_regex.match?(segment)
                  # Use CGI.escape and replace + with %20 for URL path encoding
                  CGI.escape(segment).gsub('+', '%20')
                else
                  segment
                end
              end
            end
            encoded_path = encoded_segments.join('/')
            encoded_relative_uri = query_part ? "#{encoded_path}?#{query_part}" : encoded_path
          end

          if !is_absolute_uri
            uri = (options[:base_uri] || KillBillClient::API.base_uri)
            uri = URI.parse(uri) unless uri.is_a?(URI)
            # Note: make sure to keep the full path (if any) from URI::HTTP, for non-ROOT deployments
            # See https://github.com/killbill/killbill/issues/221#issuecomment-151980263
            base_path = uri.request_uri == '/' ? '' : uri.request_uri
            uri += (base_path + encoded_relative_uri)
          else
            uri = encoded_relative_uri
            uri = URI.parse(uri) unless uri.is_a?(URI)
          end

          query_params = encode_params(options)
          if query_params && !query_params.empty?
            # encode_params returns "?param=value", so remove the leading "?"
            params_without_question = query_params[1..-1]
            if uri.query && !uri.query.empty?
              # If there's already a query string, append with &
              uri.query = uri.query + '&' + params_without_question
            else
              # If no existing query string, set it directly
              uri.query = params_without_question
            end
          end

          uri
        end

        def encode_params(options = {})
          # Plugin properties and controlPluginNames are passed in the options but we want to send them as query parameters,
          # so remove with from global hash and insert them under :params
          plugin_properties = options.delete :pluginProperty
          if plugin_properties && plugin_properties.size > 0
            options[:params] ||= {}
            options[:params][:pluginProperty] = plugin_properties.map { |p| "#{CGI.escape p.key.to_s}=#{CGI.escape p.value.to_s}" }
          end

          control_plugin_names = options.delete(:controlPluginNames)
          if control_plugin_names
            options[:params] ||= {}
            options[:params][:controlPluginName] = control_plugin_names
          end

          return nil unless (options[:params] && !options[:params].empty?)

          if (options[:return_full_stacktraces] || KillBillClient.return_full_stacktraces)
            options[:params][:withStackTrace] = true
          end

          pairs = options[:params].map { |key, value|
            next if value.nil?

            # If the value is an array, we 'demultiplex' into several
            if value.is_a? Array
              internal_pairs = value.map do |simple_value|
                "#{CGI.escape key.to_s}=#{CGI.escape simple_value.to_s}"
              end
              internal_pairs
            else
              "#{CGI.escape key.to_s}=#{CGI.escape value.to_s}"
            end
          }.compact
          pairs.flatten!
          return nil if pairs.empty?
          "?#{pairs.join '&'}"
        end

        def create_http_client(uri, options = {})
          http = ::Net::HTTP.new uri.host, uri.port
          if options[:read_timeout].is_a? Numeric
            http.read_timeout = options[:read_timeout].to_f / 1000
          elsif KillBillClient.read_timeout.is_a? Numeric
            http.read_timeout = KillBillClient.read_timeout.to_f / 1000
          end
          if options[:connection_timeout].is_a? Numeric
            http.open_timeout = options[:connection_timeout].to_f / 1000
          elsif KillBillClient.connection_timeout.is_a? Numeric
            http.open_timeout = KillBillClient.connection_timeout.to_f / 1000
          end
          http.use_ssl = uri.scheme == 'https'
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if (options[:disable_ssl_verification] || KillBillClient.disable_ssl_verification)
          http
        end

        def request(method, relative_uri, options = {})
          head = headers.dup
          head.update options[:head] if options[:head]
          head.delete_if { |_, value| value.nil? }

          uri = build_uri(relative_uri, options)
          request = METHODS[method].new uri.request_uri, head

          # Configure multi-tenancy headers, if enabled
          if (options[:api_key] || KillBillClient.api_key) && (options[:api_secret] || KillBillClient.api_secret)
            request['X-Killbill-ApiKey'] = options[:api_key] || KillBillClient.api_key
            request['X-Killbill-ApiSecret'] = options[:api_secret] || KillBillClient.api_secret
          end

          # Configure RBAC, if enabled
          username = options[:username] || KillBillClient.username
          password = options[:password] || KillBillClient.password
          bearer = options[:bearer]
          if username and password
            request.basic_auth(*[username, password].flatten[0, 2])
          elsif bearer
            request['authorization'] = 'Bearer ' + bearer
          end
          session_id = options[:session_id]
          if session_id
            request['Cookie'] = "JSESSIONID=#{session_id}"
          end

          if options[:accept]
            request['Accept'] = options[:accept]
          end

          if options[:body]
            request['Content-Type'] = options[:content_type] || content_type
            request.body = options[:body]
          end
          if options[:etag]
            request['If-None-Match'] = options[:etag]
          end
          if options[:locale]
            request['Accept-Language'] = options[:locale]
          end

          # Add auditing headers, if needed
          if options[:user]
            request['X-Killbill-CreatedBy'] = options[:user]
          end
          if options[:reason]
            request['X-Killbill-Reason'] = options[:reason]
          end
          if options[:comment]
            request['X-Killbill-Comment'] = options[:comment]
          end

          #
          # Extract profiling data map if it exists and set X-Killbill-Profiling-Req HTTP header
          # (there will be no synchronization done, so if multiple threads are running they should probably
          # pass a per-tread profiling Map)
          #
          cur_thread_profiling_data = nil
          if options[:profilingData]
            request['X-Killbill-Profiling-Req'] = 'JAXRS'
            cur_thread_profiling_data = options[:profilingData]
          end

          if options[:request_id]
            request['X-Request-Id'] = options[:request_id]
          end

          http = create_http_client uri, options
          net_http.each_pair { |key, value| http.send "#{key}=", value }

          if KillBillClient.logger
            KillBillClient.log :info, "Request method='%s', uri='%s'" % [request.method, uri]
            headers = request.to_hash
            headers['authorization'] &&= ['Basic [FILTERED]']
            KillBillClient.log :debug, headers.keys.map { |k| "#{k}='#{headers[k].join(',')}'" }.join(', ')
            if request.body && !request.body.empty? && request['Content-Type'].include?('application/json')
              KillBillClient.log :debug, "requestBody='#{request.body}'"
            end
            start_time = Time.now
          end

          response = http.start { http.request request }
          code = response.code.to_i

          # Add profiling data if required
          if cur_thread_profiling_data && response.header['X-Killbill-Profiling-Resp']
            profiling_header = JSON.parse response.header['X-Killbill-Profiling-Resp']
            jaxrs_profiling_header = profiling_header['rawData'][0]
            key = nil
            if RE_PATH.match(uri.path)
              second_arg = $2.nil? ? "" : $2
              key = "#{method}:#{$1}uuid#{second_arg}"
            else
              key = "#{method}:#{uri.path}"
            end
            if cur_thread_profiling_data[key].nil?
              cur_thread_profiling_data[key] = []
            end
            cur_thread_profiling_data[key] << jaxrs_profiling_header['durationUsec']
          end

          if KillBillClient.logger
            #noinspection RubyScope
            latency = (Time.now - start_time) * 1_000
            level = case code
                      when 200...300 then
                        :info
                      when 300...400 then
                        :warn
                      when 400...500 then
                        :error
                      else
                        :fatal
                    end
            KillBillClient.log level, "Response code='%d', reason='%s', latency='%.1f'" % [
                code,
                response.class.name[9, response.class.name.length].gsub(
                    /([a-z])([A-Z])/, '\1 \2'
                ),
                latency
            ]
            hash_response = response.to_hash
            KillBillClient.log :debug, hash_response.keys.map { |k| "#{k}='#{hash_response[k].join(',')}'" }.join(', ')
            KillBillClient.log :debug, "responseBody='#{response.body}'" if response.body
          end

          case code
            when 200...300 then
              response
            else
              raise ResponseError.error_for(code, request, response)
          end
        end
      end
    end

    extend Net::HTTPAdapter
  end
end
