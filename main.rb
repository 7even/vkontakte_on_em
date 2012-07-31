require 'bundler'
Bundler.require

VkontakteApi.configure do |config|
  config.adapter         = :em_synchrony
  config.faraday_options = { request: { timeout: 30 } }
  config.log_responses   = true
end

$client = VkontakteApi::Client.new(ENV['TOKEN'])

class Messenger
  attr_reader :long_poll_params
  
  def initialize(ws)
    @long_poll_params = $client.messages.get_long_poll_server
  end
end

EM.synchrony do
  EventMachine::WebSocket.start(host: '0.0.0.0', port: 8080) do |ws|
    ws.onopen do
      Fiber.new do
        puts 'Connection open'
        messenger = Messenger.new(ws)
        
        ws.send "Hello Client. Got long poll params: #{messenger.long_poll_params.inspect}"
      end.resume
    end
    
    ws.onclose do
      puts 'Connection closed'
    end
    
    ws.onmessage do |msg|
      puts "Received message: #{msg}"
      ws.send "Pong: #{msg}"
    end
  end
end
