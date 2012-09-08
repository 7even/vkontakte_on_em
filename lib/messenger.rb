class Messenger
  # сохраняем объект EventMachine::WebSocket в инстанс-переменной,
  # чтобы отправлять данные на фронт-энд
  def initialize(ws)
    @ws = ws
  end
  
  # запуск бесконечного цикла получения обновлений
  def start
    in_fiber do
      # получаем список друзей
      friends = $client.friends.get(fields: [:screen_name, :photo])
      # и кол-во непрочитанных сообщений, разбитое по отправителям
      unread = get_unread_messages
      # складываем в один хэш
      friends.each do |friend|
        friend.unread = unread[friend.uid]
      end
      # и отправляем фронт-энду, чтобы тот отрендерил интерфейс
      send_to_websocket(friends_list: friends)
      
      # получаем параметры long-polling
      url, params = get_polling_params
      # и делаем запросы, пока мессенджер не остановлен
      while self.running? && response = VkontakteApi::API.connection.get(url, params).body
        if response.failed?
          # время действия ключа истекло, нужно получить новый
          url, params = get_polling_params
          next
        else
          # все нормально - отправляем обновления на фронт-энд
          send_to_websocket(updates: response.updates)
          # и обновляем параметр ts для использования
          # в следующем запросе к ВКонтакте
          params[:ts] = response.ts
        end
      end
    end
  end
  
  # остановка мессенджера
  def stop
    @stopped = true
  end
  
  # запущен ли мессенджер
  def running?
    !@stopped
  end
  
  # отправка сообщения пользователю
  def send_message(params = {})
    in_fiber do
      # мини-костыль для вызова $client.messages.send
      # т.к. метод :send определен в Kernel
      VkontakteApi::Method.new('send', resolver: $client.messages).call(params)
    end
  end
  
  # загрузка сообщений, отправленных
  # до запуска мессенджера
  def load_previous_messages(params = {})
    in_fiber do
      puts "loading messages for user ##{params.uid}"
      # выбрасываем первый элемент массива (там будет общее кол-во сообщений)
      # и сортируем в хронологическом порядке
      messages = $client.messages.get_history(uid: params.uid).tap(&:shift).reverse
      
      data = {
        uid:      params.uid,
        messages: messages
      }
      # отправляем сообщения на фронт-энд с типом previous_messages
      send_to_websocket(previous_messages: data)
    end
  end
  
  # пометка сообщений прочитанными
  def mark_as_read(params = {})
    in_fiber do
      puts "marking messages #{params.mids} as read"
      $client.messages.mark_as_read(mids: params.mids)
      # на фронт-энд тут ничего отправлять не нужно,
      # т.к. изменение статуса "прочитано" придет в основном цикле
    end
  end
  
private
  # хелпер для отправки данных в веб-сокет
  def send_to_websocket(messages)
    messages.each do |type, data|
      # если data - хэш, то преобразовываем его символьные ключи в строковые
      # (дабы не получить после JSON-кодирования ":messages")
      data = data.inject({}) do |hash, (key, value)|
        hash[key.to_s] = value
        hash
      end if data.is_a?(Hash)
      
      json = Oj.dump(
        'type' => type.to_s,
        'data' => data
      )
      
      @ws.send json
    end
  end
  
  # получение параметров для long-polling запроса
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
    # снова выбрасываем первый элемент за ненадобностью
    messages.shift
    
    # и складываем все в хэш, проиндексированный по id отправителя
    counts = Hash.new(0)
    messages.inject(counts) do |hash, message|
      hash[message.uid] += 1
      hash
    end
  end
  
  # хелпер для запуска кода в отдельном файбере
  def in_fiber(&block)
    Fiber.new(&block).resume
  end
end
