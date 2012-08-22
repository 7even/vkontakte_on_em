# coffee -wc public/js/main.coffee

log = (param) -> console.log param

class Message
  constructor: (@id, flags, from_id, timestamp, @subject, @text, @attachments) ->
    @unread = flags & 1
    @outgoing = flags & 2
    @user = usersList.list[from_id]
    @date = new Date(timestamp * 1000)
    
    if @unread
      @user.unread += 1
      usersList.renderMenu()
    
    @render()
  
  read: ->
    @unread = false
  
  render: ->
    messageString = if @outgoing
      [
        '<blockquote id="' + @id + '" class="message pull-right">'
        "<p>#{@text}</p>"
        '<small><i class="icon-user"></i> Я'
        ' | ' + feed.formatDate(@date)
        '</small></blockquote>'
        '<div class="clearfix"></div>'
      ].join ' '
    else
      username = [@user.first_name, @user.last_name].join(' ')
      [
        '<blockquote id="' + @id + '" class="message">'
        "<p>#{@text}</p>"
        '<small><i class="icon-user"></i> '
        username
        ' | ' + feed.formatDate(@date)
        '</small></blockquote>'
        '<div class="clearfix"></div>'
      ].join ' '
    
    $("#user_#{@user.uid} ul.feed").append messageString

$(document).ready ->
  window.usersList =
    list: {}
    
    load: (list) ->
      for user in list
        user.unread = 0
        @list[user.uid] = user
      
      @clearOnLoad()
      @renderMenu()
      @renderPanes()
    
    # очистка и ререндер менюшки
    renderMenu: ->
      $('#navbar .user').remove()
      
      for id, user of @list
        name = "#{user.first_name} #{user.last_name}"
        
        li = '<li class="user"><a href="#user_' + id + '" id="tab_' + id + '" data-toggle="tab"><i class="icon-user"></i> ' + name
        li += ' <span class="label label-success">Online</span>' if user.online
        li += ' <span class="badge badge-warning">' + user.unread + '</span>' if user.unread > 0
        li += '</a></li>'
        
        $('#navbar').append li
    
    # метод должен вызываться один раз после загрузки usersList
    renderPanes: ->
      for id, user of @list
        name = "#{user.first_name} #{user.last_name}"
        
        pane = '<div class="tab-pane fade user" id="user_' + id + '">'
        pane += '<h6>' + name + '</h6><ul class="feed"></ul>'
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
        date.getHours().toString()
        date.getMinutes().toString()
        date.getSeconds().toString()
      ]
      
      dateParts = for part in dateParts
        if part.length is 1 then "0#{part}" else part
      
      dateParts.join ':'
    
    addStatus: (statusString, user) ->
      # добавляем полную запись (лейблы плюс юзернейм) в общий фид
      $('#feed ul.feed').append "<li>#{statusString} #{user.first_name} #{user.last_name}</li>"
      # и укороченную запись (только лейблы) в персональный фид
      $("#user_#{user.uid} ul.feed").append "<li>#{statusString}</li>"
    
    addMessage: (message, user, date, outgoing = false) ->
      # TODO: это надо делать только если не открыта таба этого юзера
      user.unread += 1
      usersList.renderMenu()
      
      messageString = if outgoing
        [
          '<blockquote class="message pull-right">'
          "<p>#{message}</p>"
          '<small><i class="icon-user"></i> Я'
          ' | ' + @formatDate(date)
          '</small></blockquote>'
          '<div class="clearfix"></div>'
        ].join ' '
      else
        username = [user.first_name, user.last_name].join(' ')
        [
          '<blockquote class="message">'
          "<p>#{message}</p>"
          '<small><i class="icon-user"></i> '
          username
          ' | ' + @formatDate(date)
          '</small></blockquote>'
          '<div class="clearfix"></div>'
        ].join ' '
      
      $("#user_#{user.uid} ul.feed").append messageString
  
  $('#navbar').on 'shown', 'li.user a[data-toggle="tab"]', (e) ->
    user_id = e.target.id.split('_')[1]
    user = usersList.list[user_id]
    
    if user.unread > 0
      user.unread = 0
      usersList.renderMenu()
  
  $(document).on 'submit', 'form.message', (e) ->
    form = $(e.target)
    message =
      uid:     form.data('user-id')
      message: form[0].message.value
    
    ws.send $.param(message)
    form[0].message.value = ''
    false
  
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
  
  ws.onclose = ->
    log 'socket closed'
