require 'bundler'
Bundler.require

require_relative 'messenger'

# нужно выключить буферизацию вывода,
# дабы видеть логгирование в реальном времени
$stdout.sync = true

VkontakteApi.configure do |config|
  config.adapter         = :em_synchrony
  config.faraday_options = { request: { timeout: 30 } }
  config.log_responses   = true
end

$client = VkontakteApi::Client.new(ENV['TOKEN'])

def in_fiber
  Fiber.new do
    yield
  end.resume
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
      data = CGI.parse(msg).inject(Hashie::Mash.new) do |mash, (key, value)|
        mash.merge(key => value.first)
      end
      
      puts "Received message: #{data.inspect}"
      
      action = data.delete(:action)
      case action
      when 'send_message'
        $messenger.send_message(data)
      when 'load_previous_messages'
        $messenger.load_previous_messages(data)
      when 'mark_as_read'
        $messenger.mark_as_read(data)
      end
    end
  end
end
