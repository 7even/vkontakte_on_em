require 'bundler'
Bundler.require

require_relative 'messenger'

# нужно выключить буферизацию вывода,
# дабы видеть логгирование в реальном времени
$stdout.sync = true

VkontakteApi.configure do |config|
  # совершаем запросы через em_synchrony-адаптер
  config.adapter = :em_synchrony
  # в основном цикле получения сообщений соединения будут
  # висеть до 25 секунд, поэтому ставим таймаут на полминуты
  config.faraday_options = { request: { timeout: 30 } }
end

# создаем клиент API, через него будем отправлять все запросы к ВКонтакте
$client = VkontakteApi::Client.new(ENV['TOKEN'])

EM.synchrony do
  EventMachine::WebSocket.start(host: '0.0.0.0', port: 8080) do |ws|
    ws.onopen do
      # при открытии соединения с браузером создаем новый мессенджер
      puts 'Connection open'
      $messenger = Messenger.new(ws)
      $messenger.start
    end
    
    ws.onclose do
      # при закрытии соединения останавливаем мессенджер,
      # чтобы он перестал запрашивать обновления
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
      if %w[send_message load_previous_messages mark_as_read].include?(action)
        $messenger.send(action, data)
      end
    end
  end
end
