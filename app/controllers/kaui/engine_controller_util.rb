module Kaui::EngineControllerUtil

  protected

  def get_layout
    layout ||= Kaui.config[:layout]
  end

  def paginate(searcher, data_extractor, formatter)
    search_key = (params[:search] || {})[:value].presence
    offset = (params[:start] || 0).to_i
    limit = (params[:length] || 10).to_i

    limit = 2147483647 if limit == -1

    begin
      pages = searcher.call(search_key, offset, limit)
    rescue => e
      error = e.to_s
    end

    json = {
        :draw => (params[:draw] || 0).to_i,
        :recordsTotal => pages.nil? ? 0 : pages.pagination_max_nb_records,
        :recordsFiltered => pages.nil? ? 0 : pages.pagination_total_nb_records,
        :data => []
    }
    json[:error] = error unless error.nil?

    pages ||= []

    # Until we support server-side sorting
    ordering = ((params[:order] || {})[:'0'] || {})
    ordering_column = (ordering[:column] || 0).to_i
    ordering_dir = ordering[:dir] || 'asc'
    pages.sort! { |a, b| data_extractor.call(a, ordering_column) <=> data_extractor.call(b, ordering_column) }
    pages.reverse! if ordering_dir == 'desc'

    pages.each { |page| json[:data] << formatter.call(page) }

    respond_to do |format|
      format.json { render :json => json }
    end
  end

  def run_in_parallel(*tasks)
    latch = Concurrent::CountDownLatch.new(tasks.size)
    exceptions = Concurrent::Array.new

    tasks.each do |task|
      Kaui.thread_pool.post do
        begin
          task.call
        rescue => e
          exceptions << e
        ensure
          latch.count_down
        end
      end
    end
    latch.wait

    exception = exceptions.shift
    raise exception unless exception.nil?
  end

  def as_string(e)
    if e.is_a?(KillBillClient::API::ResponseError)
      "Error #{e.response.code}: #{as_string_from_response(e.response.body)}"
    else
      e.message
    end
  end

  def as_string_from_response(response)
    error_message = response
    begin
      # BillingExceptionJson?
      error_message = JSON.parse response
    rescue => e
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
end
