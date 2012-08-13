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
      send_to_websocket(friends_list: friends)
      
      url, params = get_polling_params
      while !@stopped && response = VkontakteApi::API.connection.get(url, params).body
        if response.failed?
          # время действия ключа истекло, нужно получить новый
          url, params = get_polling_params
          next
        else
          send_to_websocket(updates: response.updates)
          params[:ts] = response.ts
        end
      end
    end.resume
  end
  
  def stop
    @stopped = true
  end
  
private
  def send_to_websocket(messages)
    messages.each do |type, data|
      json = Oj.dump(
        'type' => type.to_s,
        'data' => data
      )
      
      @ws.send json
    end
  end
  
  def get_polling_params
    params = $client.messages.get_long_poll_server
    
    [
      'http://' + params.delete(:server),
      params.merge(act: 'a_check', wait: 25, mode: 2)
    ]
  end
end

EM.synchrony do
  EventMachine::WebSocket.start(host: '0.0.0.0', port: 8080) do |ws|
    ws.onopen do
      puts 'Connection open'
      $messenger = Messenger.new(ws)
      $messenger.start
      
      # ws.send 'Hello Client.'
    end
    
    ws.onclose do
      $messenger.stop
      puts 'Connection closed'
    end
    
    ws.onmessage do |msg|
      puts "Received message: #{msg}"
      ws.send Oj.dump('pong' => msg)
    end
  end
end
