require 'bundler'
Bundler.require

VkontakteApi.configure do |config|
  config.adapter         = :em_synchrony
  config.faraday_options = { request: { timeout: 30 } }
  config.log_responses   = true
end

$client = VkontakteApi::Client.new(ENV['TOKEN'])

class Messenger
  def initialize(ws)
    @ws = ws
  end
  
  def start
    Fiber.new do
      friends = $client.friends.get(fields: [:screen_name, :photo])
      @ws.send Oj.dump('type' => 'friends_list', 'data' => friends)
      
      params = $client.messages.get_long_poll_server
      # @ws.send Oj.dump(params)
      url = 'http://' + params.delete(:server)
      params.update(act: 'a_check', wait: 25, mode: 2)
      
      while response = VkontakteApi::API.connection.get(url, params).body
        @ws.send Oj.dump('type' => 'updates', 'data' => response.updates)
        params[:ts] = response.ts
      end
    end.resume
  end
end

EM.synchrony do
  EventMachine::WebSocket.start(host: '0.0.0.0', port: 8080) do |ws|
    ws.onopen do
      puts 'Connection open'
      messenger = Messenger.new(ws)
      messenger.start
      
      # ws.send 'Hello Client.'
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
