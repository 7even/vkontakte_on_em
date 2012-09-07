class Message
  constructor: (@id, flags, from_id, timestamp, @subject, @text, @attachments) ->
    @unread = !!(flags & 1)
    @outgoing = !!(flags & 2)
    @user = usersList.list[from_id]
    @date = new Date(timestamp * 1000)
    
    @user.addMessage this
    @render()
  
  unreadAndIncoming: ->
    @unread and !@outgoing
  
  # помечаем сообщение прочитанным в интерфейсе приложения
  # (используется, когда ВКонтакте сообщает, что это сообщение прочитано)
  read: ->
    @unread = false
    
    # если сообщение входящее, нужно заново отрендерить меню
    unless @outgoing
      # а если у юзера еще не загружены предыдущие сообщения,
      # надо еще и вычесть единицу из счетчика
      @user.unread -= 1 unless @user.previousMessagesLoaded
      usersList.renderMenu()
  
  render: ->
    classes = ['message']
    classes.push 'pull-right' if @outgoing
    sender = if @outgoing then 'Я' else @user.name
    
    messageString = '<blockquote id="' + @id + '" class="' + classes.join(' ') + '">'
    messageString += "<p>#{@text}</p>"
    messageString += '<small><i class="icon-user"></i> ' + sender
    messageString += ' | ' + feed.formatDate(@date) + '</small>'
    messageString += '</blockquote>'
    messageString += '<div class="clearfix"></div>'
    
    $("#user_#{@user.uid} ul.feed").append messageString
