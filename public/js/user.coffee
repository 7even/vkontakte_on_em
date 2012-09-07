class User
  constructor: (data) ->
    @uid    = data.uid
    @name   = [data.first_name, data.last_name].join(' ')
    @online = data.online
    
    # счетчик непрочитанных сообщений,
    # нужный на то время, пока @previousMessagesLoaded = false;
    # потом подсчет идет по @messages
    @unread = data.unread
    
    @messages = {}
    @previousMessagesLoaded = false
  
  # перегруженная функция:
  # без параметров запрашивает сообщения у бэк-энда;
  # когда тот отвечает, эта же функция вызывается
  # с полученными сообщениями, и происходит рендеринг
  loadPreviousMessages: (messages) ->
    if messages?
      # очищаем все уже загруженные сообщения
      @messages = {}
      $("#user_#{@uid} ul.feed").html('')
      
      # и рендерим полученные сообщения
      for message in messages
        unread = if (message.read_state == 1) then 0 else 1
        flags = unread + message.out * 2
        
        params = [
          message.mid
          flags
          @uid
          message.date
          null
          message.body
          message.attachments
        ]
        # сообщение рендерится в конструкторе Message
        new Message(params...)
      
      @previousMessagesLoaded = true
      # если открыта таба этого пользователя,
      # нужно сразу пометить все сообщения прочитанными
      @markAllAsRead() if @paneActive()
    else
      # запрашиваем сообщения из вебсокета
      data =
        action: 'load_previous_messages'
        uid:    @uid
      ws.send $.param(data)
  
  unreadCount: ->
    # кол-во непрочитанных входящих сообщений считается по-разному
    # в зависимости от @previousMessagesLoaded:
    if @previousMessagesLoaded
      # когда предыдущие сообщения уже загружены в @messages,
      # обходим их и подсчитываем
      @unreadMessagesIds().length
    else
      # до загрузки предыдущих сообщений считаем по @unread, полученной
      # при изначальной загрузке списка пользователей
      @unread
  
  hasUnread: ->
    @unreadCount() > 0
  
  paneActive: ->
    $("#user_#{@uid}").hasClass('active')
  
  unreadMessagesIds: ->
    # возвращаем id непрочитанных входящих сообщений из @messages
    id for id, message of @messages when message.unreadAndIncoming()
  
  addMessage: (message) ->
    @messages[message.id] = message
    
    # если кол-во непрочитанных входящих изменилось, рендерим меню
    if message.unreadAndIncoming()
      # если предыдущие сообщения еще не загружены, увеличиваем счетчик
      @unread += 1 if !@previousMessagesLoaded
      usersList.renderMenu()
    
    # если панель активна, сразу помечаем все сообщения прочитанными
    @markAllAsRead() if @paneActive()
  
  markAllAsRead: ->
    if @previousMessagesLoaded and @hasUnread()
      message =
        action: 'mark_as_read'
        mids:   @unreadMessagesIds().join(',')
      ws.send $.param(message)
