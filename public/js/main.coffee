# coffee -wc public/js/main.coffee

log = (param) -> console.log param

$(document).ready ->
  usersList =
    list: {}
    
    load: (list) ->
      @list[user.uid] = user for user in list
      @clearOnLoad()
      @render()
    
    render: ->
      @clear()
      
      @renderUser user for uid, user of @list
      
    renderUser: (user) ->
      name = "#{user.first_name} #{user.last_name}"
      
      li = '<li class="user"><a href="#user_' + user.uid + '" data-toggle="tab"><i class="icon-user"></i> ' + name
      li += ' <span class="label label-success">Online</span>' if user.online
      li += '</a></li>'
      
      pane = '<div class="tab-pane fade user" id="user_' + user.uid + '"><h6>' + name + '</h6></div>'
      
      $('#navbar').append li
      $('#main').append pane
    
    clear: ->
      $('.user').remove()
    
    clearOnLoad: ->
      $('.loading').remove()
  
  feed =
    process: (updates) ->
      for update in updates
        code = update[0]
        id = update[1]
        
        switch code
          when 8
            # друг $user_id стал онлайн
            user = usersList.list[-id]
            user.online = 1
            usersList.render()
            @add "#{user.first_name} #{user.last_name} online"
          when 9
            # друг $user_id стал оффлайн
            user = usersList.list[-id]
            user.online = 0
            usersList.render()
            @add "#{user.first_name} #{user.last_name} offline"
    
    add: (string) ->
      $('#feed ul').append "<li>#{string}</li>"
  
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
