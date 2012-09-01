class Messenger
  def initialize(ws)
    @ws = ws
  end
  
  def start
    in_fiber do
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
    end
  end
  
  def stop
    @stopped = true
  end
  
  def send_message(params = {})
    in_fiber do
      # мини-костыль для вызова $client.messages.send
      VkontakteApi::Method.new('send', resolver: $client.messages).call(params)
    end
  end
  
  def load_previous_messages(params = {})
    in_fiber do
      puts "loading messages for user ##{params.uid}"
      messages = $client.messages.get_history(uid: params.uid).tap(&:shift).reverse
      
      data = {
        uid:      params.uid,
        messages: messages
      }
      send_to_websocket(previous_messages: data)
    end
  end
  
  def mark_as_read(params = {})
    in_fiber do
      puts "marking messages #{params.mids} as read"
      $client.messages.mark_as_read(mids: params.mids)
    end
  end
  
private
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
