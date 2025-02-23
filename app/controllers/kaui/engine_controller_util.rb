# frozen_string_literal: true

module Kaui
  module EngineControllerUtil
    # See DefaultPaginationSqlDaoHelper.java
    SIMPLE_PAGINATION_THRESHOLD = 20_000
    MAXIMUM_NUMBER_OF_RECORDS_DOWNLOAD = 1000

    protected

    # rubocop:disable Lint/UselessAssignment, Naming/AccessorMethodName
    def get_layout
      layout ||= Kaui.config[:layout]
    end
    # rubocop:enable Lint/UselessAssignment, Naming/AccessorMethodName

    def paginate(searcher, data_extractor, formatter, table_default_columns = [])
      search_key = (params[:search] || {})[:value].presence
      offset = (params[:start] || 0).to_i
      limit = (params[:length] || 10).to_i

      limit = -limit if params[:ordering] == 'desc'
      begin
        pages = searcher.call(search_key, offset, limit)
      rescue StandardError => e
        error = e.to_s
      end

      json = {
        draw: (params[:draw] || 0).to_i,
        # We need to fill-in a number to make DataTables happy
        recordsTotal: pages.nil? ? 0 : (pages.pagination_max_nb_records || SIMPLE_PAGINATION_THRESHOLD),
        recordsFiltered: pages.nil? ? 0 : (pages.pagination_total_nb_records || SIMPLE_PAGINATION_THRESHOLD),
        data: [],
        columns: table_default_columns
      }
      json[:error] = error unless error.nil?

      pages ||= []

      # Until we support server-side sorting
      ordering = (params[:order] || {})[:'0'] || {}
      ordering_column = (ordering[:column] || 0).to_i
      ordering_column = params[:colum_order][ordering_column].to_i if params[:colum_order].present?
      ordering_dir = ordering[:dir] || 'asc'
      unless search_key.nil?
        pages.sort! do |a, b|
          a = data_extractor.call(a, ordering_column)
          b = data_extractor.call(b, ordering_column)
          sort = a <=> b
          sort.nil? ? -1 : sort
        end
      end
      pages.reverse! if (ordering_dir == 'desc' && limit >= 0) || (ordering_dir == 'asc' && limit.negative?)

      pages.each { |page| json[:data] << formatter.call(page) }

      respond_to do |format|
        format.json { render json: }
      end
    end

    def promise(&)
      # Evaluation starts immediately
      ::Concurrent::Promises.future do
        # https://github.com/rails/rails/issues/26847
        Rails.application.executor.wrap(&)
      end
    end

    def wait(promise)
      # https://github.com/rails/rails/issues/26847
      ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
        # Make sure to set a timeout to avoid infinite wait
        value = promise.value!(60)
        raise promise.reason unless promise.reason.nil?

        if value.nil? && promise.state != :fulfilled
          # Could be https://github.com/ruby-concurrency/concurrent-ruby/issues/585
          Rails.logger.warn("Unable to run promise #{promise_as_string(promise)}")
          raise Timeout::Error
        end
        value
      end
    end

    def promise_as_string(promise)
      return 'nil' if promise.nil?

      executor = promise.instance_variable_get('@executor')
      executor_as_string = "queue_length=#{executor.queue_length}, pool_size=#{executor.length}"
      "#{promise.instance_variable_get('@promise_body')}[state=#{promise.state}, parent=#{promise_as_string(promise.instance_variable_get('@parent'))}, executor=[#{executor_as_string}]]"
    end

    # Used to format flash error messages
    def as_string(exception)
      if exception.is_a?(KillBillClient::API::ResponseError)
        as_string_from_response(exception.response.body)
      elsif exception.is_a?(ActionController::ParameterMissing)
        # e.message contains corrections, which we don't want
        "missing parameter #{exception.param}"
      elsif exception.respond_to?(:cause) && !exception.cause.nil?
        as_string(exception.cause)
      else
        log_rescue_error(exception)
        exception.message
      end
    end

    def log_rescue_error(error)
      Rails.logger.warn "#{error.class} #{error}. #{error.backtrace.join("\n")}"
    end

    def as_string_from_response(response)
      error_message = response
      begin
        # BillingExceptionJson?
        error_message = JSON.parse response
      rescue StandardError => _e
        # Ignore
      end

      if error_message.respond_to?(:[]) && error_message['message'].present?
        # Likely BillingExceptionJson
        error_message = error_message['message']
        error_message += " (code=#{error_message['code']})" unless error_message['code'].blank?
      end
      # Limit the error size to avoid ActionDispatch::Cookies::CookieOverflow
      error_message[0..1000]
    end

    def nested_hash_value(obj, key)
      if obj.respond_to?(:key?) && obj.key?(key)
        obj[key]
      elsif obj.is_a?(Hash) || obj.is_a?(Array)
        r = nil
        obj.find { |*a| r = nested_hash_value(a.last, key) }
        r
      else
        nil
      end
    end

    def json_response
      begin
        response = yield
        response_status = 200
      rescue KillBillClient::API::ResponseError => e
        response = as_string_from_response(e.response.body)
        response_status = e.code
      rescue StandardError => e
        response = e.message
        response_status = 500
      end
      render json: response, status: response_status
    end

    def default_columns(fields, sensivite_fields)
      fields.map { |field| { data: fields.index(field), visible: !(sensivite_fields.include? field) } }
    end
  end
end
