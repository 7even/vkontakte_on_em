# coffee -wc public/js/main.coffee

$(document).ready ->
  navbar = $('#navbar')
  main = $('#main')
  
  usersList =
    list: []
    
    load: (list) ->
      @list = list
      @render()
    
    render: ->
      navbar.empty()
      main.empty()
      @renderTab 'debug', 'Debug info', true
      
      $(@list).each (index, user) =>
        id = 'user' + user.uid
        name = user.first_name + ' ' + user.last_name
        @renderTab id, name
      
    renderTab: (id, name, active = false) ->
      li = '<li' + (if active then ' class="active"' else '') + '><a href="#' + id + '" data-toggle="tab">' + name + '</a></li>'
      pane = '<div class="tab-pane' + (if active then ' active' else '') + '" id="' + id + '"><h6>' + name + '</h6></div>'
      
      navbar.append li
      main.append pane
    
  
  ws = new WebSocket 'ws://0.0.0.0:8080'
  ws.onmessage = (event) ->
    message = $.parseJSON event.data
    console.log 'received message from server:'
    console.log message
    
    usersList.load message.data if message.type == 'friends_list'
    
    $('#debug').append '<pre>' + event.data + '</pre>'
  
  ws.onopen = ->
    console.log 'connected...'
    # ws.send 'hello server'
  
  ws.onclose = ->
    console.log 'socket closed'
