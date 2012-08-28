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
    else
      # запрашиваем сообщения из вебсокета
      log "requesting messages history for user ##{@uid}"
