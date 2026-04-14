module KillBillClient
  module Model
    class Export < Resource
      
      KILLBILL_API_EXPORT_PREFIX = "#{KILLBILL_API_PREFIX}/export"
      
      class << self
        
        def find_by_account_id(account_id, user = 'Ruby_Client', options = {}, reason = nil, comment = nil)
          
          get "#{KILLBILL_API_EXPORT_PREFIX}/#{account_id}",
          {},
          {
            :accept => 'application/octet-stream',
            :user    => user,
            :reason  => reason,
            :comment => comment      
          }.merge(options)
          
        end
        
      end
     
    end
  end
end