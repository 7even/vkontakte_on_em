log = (param) -> console.log param

$(document).ready ->
  window.usersList =
    list: {}
    
    load: (list) ->
      for user_attributes in list
        @list[user_attributes.uid] = new User(user_attributes)
      
      @clearOnLoad()
      @renderMenu()
      @renderPanes()
    
    # очистка и ререндер менюшки
    renderMenu: ->
      # запоминаем активную табу
      activeTabId = $('li.active a').attr('id')
      # чистим меню
      $('#navbar .user').remove()
      
      # наполняем заново
      for id, user of @list
        li = '<li class="user"><a href="#user_' + id + '" id="tab_' + id + '" data-toggle="tab">'
        li += '<i class="icon-user"></i> ' + user.name
        li += ' <span class="label label-success">Online</span>' if user.online
        li += ' <span class="badge badge-warning">' + user.unreadCount() + '</span>' if user.hasUnread()
        li += '</a></li>'
        
        $('#navbar').append li
      
      # восстанавливаем активную табу
      $('#' + activeTabId).parent().addClass('active')
    
    # метод должен вызываться один раз после загрузки usersList
    renderPanes: ->
      for id, user of @list
        pane = '<div class="tab-pane fade user" id="user_' + id + '">'
        pane += '<h6>' + user.name + '</h6><ul class="feed"></ul>'
        pane += '<form class="well message" data-user-id="' + id + '">'
        pane += '<textarea class="span8" name="message" placeholder="Сообщение"></textarea>'
        pane += '<button class="btn btn-primary" type="submit">Отправить</button>'
        pane += '</form></div>'
        
        $('#main').append pane
    
    clearOnLoad: ->
      $('.loading').remove()
  
  window.feed =
    process: (updates) ->
      for update in updates
        code = update.shift()
        
        switch code
          # изменение флагов сообщения
          when 3
            [message_id, flags, user_id] = update
            usersList.list[user_id].messages[message_id].read() if flags & 1
          
          # добавление нового сообщения
          when 4
            message = new Message(update...)
          
          # друг $user_id стал онлайн(8) / оффлайн(9)
          when 8, 9
            user_id = update[0]
            user = usersList.list[-user_id]
            user.online = if code == 8 then 1 else 0
            usersList.renderMenu()
            
            date = '<span class="badge">' + @formatDate() + '</span>'
            if code == 8
              label = '<span class="label label-info">online</span>'
            else
              label = '<span class="label label-important">offline</span>'
            
            @addStatus [date, label].join(' '), user
    
    formatDate: (date = new Date) ->
      dateParts = [
        date.getDate()
        date.getMonth() + 1
        date.getFullYear()
      ]
      
      today = new Date
      if dateParts[0] == today.getDate() and dateParts[1] == today.getMonth() + 1 and dateParts[2] == today.getFullYear()
        dateString = 'сегодня'
      else
        dateParts = for part in dateParts
          if part.toString().length is 1 then "0#{part}" else part
        dateString = dateParts.join '.'
      
      timeParts = [
        date.getHours()
        date.getMinutes()
        date.getSeconds()
      ]
      
      timeParts = for part in timeParts
        if part.toString().length is 1 then "0#{part}" else part
      timeString = timeParts.join ':'
      
      "#{dateString} в #{timeString}"
    
    addStatus: (statusString, user) ->
      # добавляем полную запись (лейблы плюс юзернейм) в общий фид
      $('#feed ul.feed').append "<li>#{statusString} #{user.name}</li>"
      # и укороченную запись (только лейблы) в персональный фид
      $("#user_#{user.uid} ul.feed").append "<li>#{statusString}</li>"
  
  # обработчик перехода в табу юзера
  $('#navbar').on 'shown', 'li.user a[data-toggle="tab"]', (e) ->
    user_id = e.target.id.split('_')[1]
    user = usersList.list[user_id]
    
    # если предыдущие сообщения еще не загружены, грузим
    user.loadPreviousMessages() unless user.previousMessagesLoaded
    
    # если есть непрочитанные сообщения - помечаем прочитанными
    user.markAllAsRead()
  
  # обработчик сабмита формы
  $(document).on 'submit', 'form.message', (e) ->
    form = $(e.target)
    message =
      action:  'send_message'
      uid:     form.data('user-id')
      message: form[0].message.value
    
    ws.send $.param(message)
    form[0].message.value = ''
    false
  
  window.ws = new WebSocket('ws://0.0.0.0:8080')
  ws.onmessage = (event) ->
    message = $.parseJSON event.data
    
    switch message.type
      when 'friends_list'
        usersList.load message.data
      when 'previous_messages'
        usersList.list[message.data.uid].loadPreviousMessages message.data.messages
      when 'updates'
        feed.process message.data
      else
        log 'received unknown message:'
        log message
    
    $('#debug').append '<pre>' + event.data + '</pre>'
  
  ws.onopen = ->
    log 'connected...'
  
  ws.onclose = ->
    log 'socket closed'
