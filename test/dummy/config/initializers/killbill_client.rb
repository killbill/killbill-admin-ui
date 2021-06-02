KillBillClient.url = ENV['KILLBILL_URL'] || 'http://127.0.0.1:8080'
KillBillClient.read_timeout = (ENV['KILLBILL_READ_TIMEOUT'] || 60000).to_i
KillBillClient.connection_timeout = (ENV['KILLBILL_CONNECTION_TIMEOUT'] || 60000).to_i
