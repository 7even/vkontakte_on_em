require 'bundler'
Bundler.require

# нужно выключить буферизацию вывода,
# дабы видеть логгирование в реальном времени
$stdout.sync = true

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
      unread = get_unread_messages
      friends.each do |friend|
        friend.unread = unread[friend.uid]
      end
      
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
  
  def send_message(params = {})
    Fiber.new do
      # мини-костыль для вызова $client.messages.send
      VkontakteApi::Method.new('send', resolver: $client.messages).call(params)
    end.resume
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
  
  # кол-во непрочитанных входящих сообщений, разбитое по отправителям
  def get_unread_messages
    messages = $client.messages.get(filters: 1)
    messages.shift
    
    counts = Hash.new(0)
    messages.inject(counts) do |hash, message|
      hash[message.uid] += 1
      hash
    end
  end
end

EM.synchrony do
  EventMachine::WebSocket.start(host: '0.0.0.0', port: 8080) do |ws|
    ws.onopen do
      puts 'Connection open'
      $messenger = Messenger.new(ws)
      $messenger.start
    end
    
    ws.onclose do
      $messenger.stop
      puts 'Connection closed'
    end
    
    ws.onmessage do |msg|
      # сообщение приходит в формате uid=12345&message=abcde
      # парсим его в Hashie::Mash и отправляем мессенджеру
      message_params = CGI.parse(msg).inject(Hashie::Mash.new) do |mash, (key, value)|
        mash.merge(key => value.first)
      end
      $messenger.send_message(message_params)
      
      puts "Received message: #{message_params.inspect}"
      ws.send Oj.dump('pong' => msg)
    end
  end
end
