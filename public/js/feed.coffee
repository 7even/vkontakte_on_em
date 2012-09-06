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
