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
      @markAllAsRead() if @paneActive()
    else
      # запрашиваем сообщения из вебсокета
      data =
        action: 'load_previous_messages'
        uid:    @uid
      ws.send $.param(data)
  
  paneActive: ->
    $("#user_#{@uid}").hasClass('active')
  
  unreadMessagesIds: ->
    ids = $("#user_#{@uid} ul.feed blockquote[data-unread=true]").map -> @id
    $.makeArray(ids)
  
  markAllAsRead: ->
    if @previousMessagesLoaded and @unread > 0
      message =
        action: 'mark_as_read'
        mids:   @unreadMessagesIds().join(',')
      ws.send $.param(message)
      
      # TODO: перенести сброс счетчика в обработку апдейтов
      # и там же ставить прочитанным data-unread=false
      @unread = 0
      usersList.renderMenu()
