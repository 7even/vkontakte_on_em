# coffee -wc public/js/main.coffee

log = (param) -> console.log param

$(document).ready ->
  usersList =
    list: {}
    
    load: (list) ->
      @list[user.uid] = user for user in list
      
      @clearOnLoad()
      @renderMenu()
      @renderPanes()
    
    # очистка и ререндер менюшки
    renderMenu: ->
      $('#navbar .user').remove()
      
      for id, user of @list
        name = "#{user.first_name} #{user.last_name}"
        
        li = '<li class="user"><a href="#user_' + id + '" data-toggle="tab"><i class="icon-user"></i> ' + name
        li += ' <span class="label label-success">Online</span>' if user.online
        li += '</a></li>'
        
        $('#navbar').append li
    
    # метод должен вызываться один раз после загрузки usersList
    renderPanes: ->
      for id, user of @list
        name = "#{user.first_name} #{user.last_name}"
        
        pane = '<div class="tab-pane fade user" id="user_' + id + '">'
        pane += '<h6>' + name + '</h6><ul class="feed"></ul></div>'
        
        $('#main').append pane
    
    clearOnLoad: ->
      $('.loading').remove()
  
  feed =
    process: (updates) ->
      for update in updates
        code = update[0]
        id = update[1]
        
        switch code
          # друг $user_id стал онлайн(8) / оффлайн(9)
          when 8, 9
            user = usersList.list[-id]
            user.online = if code == 8 then 1 else 0
            usersList.renderMenu()
            
            date = '<span class="badge">' + @formatDate() + '</span>'
            if code == 8
              label = '<span class="label label-info">online</span>'
            else
              label = '<span class="label label-important">offline</span>'
            
            @add [date, label].join(' '), user
    
    formatDate: (date = new Date) ->
      dateParts = [
        date.getHours().toString()
        date.getMinutes().toString()
        date.getSeconds().toString()
      ]
      
      dateParts = for part in dateParts
        if part.length is 1 then "0#{part}" else part
      
      dateParts.join ':'
    
    add: (labels, user) ->
      # добавляем полную запись (лейблы плюс юзернейм) в общий фид
      $('#feed ul.feed').append "<li>#{labels} #{user.first_name} #{user.last_name}</li>"
      # и укороченную запись (только лейблы) в персональный фид
      $("#user_#{user.uid} ul.feed").append "<li>#{labels}</li>"
  
  ws = new WebSocket 'ws://0.0.0.0:8080'
  ws.onmessage = (event) ->
    message = $.parseJSON event.data
    
    switch message.type
      when 'friends_list' then usersList.load message.data
      when 'updates'      then feed.process message.data
      else
        log 'received unknown message:'
        log message
    
    $('#debug').append '<pre>' + event.data + '</pre>'
  
  ws.onopen = ->
    log 'connected...'
    # @send 'hello server'
  
  ws.onclose = ->
    log 'socket closed'
