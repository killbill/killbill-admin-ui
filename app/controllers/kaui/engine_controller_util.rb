module Kaui::EngineControllerUtil

  # See DefaultPaginationSqlDaoHelper.java
  SIMPLE_PAGINATION_THRESHOLD = 20000

  protected

  def get_layout
    layout ||= Kaui.config[:layout]
  end

  def paginate(searcher, data_extractor, formatter)
    search_key = (params[:search] || {})[:value].presence
    offset = (params[:start] || 0).to_i
    limit = (params[:length] || 10).to_i

    limit = -limit if params[:ordering] == 'desc'
    begin
      pages = searcher.call(search_key, offset, limit)
    rescue => e
      error = e.to_s
    end

    json = {
        :draw => (params[:draw] || 0).to_i,
        # We need to fill-in a number to make DataTables happy
        :recordsTotal => pages.nil? ? 0 : (pages.pagination_max_nb_records || SIMPLE_PAGINATION_THRESHOLD),
        :recordsFiltered => pages.nil? ? 0 : (pages.pagination_total_nb_records || SIMPLE_PAGINATION_THRESHOLD),
        :data => []
    }
    json[:error] = error unless error.nil?

    pages ||= []

    # Until we support server-side sorting
    ordering = ((params[:order] || {})[:'0'] || {})
    ordering_column = (ordering[:column] || 0).to_i
    ordering_dir = ordering[:dir] || 'asc'
    pages.sort! do |a, b|
      a = data_extractor.call(a, ordering_column)
      b = data_extractor.call(b, ordering_column)
      sort = a <=> b
      sort.nil? ? -1 : sort
    end unless search_key.nil? # Keep DB ordering when listing all entries
    pages.reverse! if ordering_dir == 'desc' && limit >= 0 || ordering_dir == 'asc' && limit < 0

    pages.each { |page| json[:data] << formatter.call(page) }

    respond_to do |format|
      format.json { render :json => json }
    end
  end

  def promise(execute = true, &block)
    promise = Concurrent::Promise.new({:executor => Kaui.thread_pool}, &block)
    promise.execute if execute
    promise
  end

  def wait(promise)
    # If already executed, no-op
    promise.execute

    # Make sure to set a timeout to avoid infinite wait
    value = promise.value!(60)
    raise promise.reason unless promise.reason.nil?
    if value.nil? && promise.state != :fulfilled
      Rails.logger.warn("Unable to run promise #{promise_as_string(promise)}")
      raise Timeout::Error
    end
    value
  end

  def promise_as_string(promise)
    return 'nil' if promise.nil?
    executor = promise.instance_variable_get('@executor')
    executor_as_string = "queue_length=#{executor.queue_length}, pool_size=#{executor.length}"
    "#{promise.instance_variable_get('@promise_body')}[state=#{promise.state}, parent=#{promise_as_string(promise.instance_variable_get('@parent'))}, executor=[#{executor_as_string}]]"
  end

  # Used to format flash error messages
  def as_string(e)
    if e.is_a?(KillBillClient::API::ResponseError)
      "Error #{e.response.code}: #{as_string_from_response(e.response.body)}"
    else
      log_rescue_error(e)
      e.message
    end
  end

  def log_rescue_error(error)
    Rails.logger.warn "#{error.class} #{error.to_s}. #{error.backtrace.join("\n")}"
  end

  def as_string_from_response(response)
    error_message = response
    begin
      # BillingExceptionJson?
      error_message = JSON.parse response
    rescue => _
    end

    if error_message.respond_to? :[] and error_message['message'].present?
      # Likely BillingExceptionJson
      error_message = error_message['message']
    end
    # Limit the error size to avoid ActionDispatch::Cookies::CookieOverflow
    error_message[0..1000]
  end

  def nested_hash_value(obj, key)
    if obj.respond_to?(:key?) && obj.key?(key)
      obj[key]
    elsif obj.is_a?(Hash) or obj.is_a?(Array)
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
      response = e.response.message
      response_status = e.code
    rescue Exception => e
      response = e.message
      response_status = 500
    end
    render :json => response,  :status => response_status
  end
end
