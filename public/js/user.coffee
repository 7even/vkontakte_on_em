class User
  constructor: (data) ->
    @uid    = data.uid
    @name   = [data.first_name, data.last_name] .join(' ')
    @online = data.online
    @unread = data.unread
    
    @previousMessagesLoaded = false
  
  loadPreviousMessages: (messages) ->
    if messages?
      # очищаем все уже загруженные сообщения
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
        new Message(params...)
      
      @previousMessagesLoaded = true
    else
      # запрашиваем сообщения из вебсокета
      data =
        action: 'load_previous_messages'
        uid:    @uid
      ws.send $.param(data)
  
  paneActive: ->
    $("#user_#{@uid}").hasClass('active')
  
  unreadMessagesIds: ->
    $("#user_#{@uid} ul.feed blockquote[data-unread=true]").map -> @id
