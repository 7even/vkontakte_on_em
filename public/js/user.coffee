class User
  constructor: (data) ->
    @uid    = data.uid
    @name   = [data.first_name, data.last_name] .join(' ')
    @online = data.online
    @unread = data.unread
    
    @previousMessagesLoaded = false
  
  loadPreviousMessages: (messages) ->
    if messages?
      # рендерим полученные сообщения
      log 'received previous messages:'
      log messages
    else
      # запрашиваем сообщения из вебсокета
      log "requesting messages history for user ##{@uid}"
      data =
        action: 'load_previous_messages'
        uid:    @uid
      ws.send $.param(data)
