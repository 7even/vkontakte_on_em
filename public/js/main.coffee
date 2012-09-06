# хелпер для логгирования
log = (param) -> console.log param

$(document).ready ->
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
  
  # обработчик сообщений от бэк-энда
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
