class Message
  constructor: (@id, flags, from_id, timestamp, @subject, @text, @attachments) ->
    @unread = !!(flags & 1)
    @outgoing = !!(flags & 2)
    @user = usersList.list[from_id]
    @date = new Date(timestamp * 1000)
    
    # если это непрочитанное входящее сообщение,
    # и панель этого юзера неактивна, добавляем сообщение в счетчик
    if @unread && !@outgoing && !@user.paneActive()
      @user.unread += 1
      usersList.renderMenu()
    
    @render()
  
  read: ->
    @unread = false
  
  render: ->
    classes = ['message']
    classes.push 'pull-right' if @outgoing
    sender = if @outgoing then 'Я' else @user.name
    
    messageString = '<blockquote id="' + @id + '" class="' + classes.join(' ') + '"'
    messageString += ' data-unread=' + @unread + '>'
    messageString += "<p>#{@text}</p>"
    messageString += '<small><i class="icon-user"></i> ' + sender
    messageString += ' | ' + feed.formatDate(@date) + '</small>'
    messageString += '</blockquote>'
    messageString += '<div class="clearfix"></div>'
    
    $("#user_#{@user.uid} ul.feed").append messageString
