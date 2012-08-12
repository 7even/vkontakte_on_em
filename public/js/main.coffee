# coffee -wc public/js/main.coffee

$(document).ready ->
  usersList =
    list: []
    
    load: (list) ->
      @list = list
      @clearOnLoad()
      @render()
    
    render: ->
      @clear()
      
      $(@list).each (index, user) => @renderUser user
      
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
  
  ws = new WebSocket 'ws://0.0.0.0:8080'
  ws.onmessage = (event) ->
    message = $.parseJSON event.data
    console.log 'received message from server:'
    console.log message
    
    usersList.load message.data if message.type == 'friends_list'
    
    $('#debug').append '<pre>' + event.data + '</pre>'
  
  ws.onopen = ->
    console.log 'connected...'
    # @send 'hello server'
  
  ws.onclose = ->
    console.log 'socket closed'
