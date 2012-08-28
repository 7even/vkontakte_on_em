class Message
  constructor: (@id, flags, from_id, timestamp, @subject, @text, @attachments) ->
    @unread = flags & 1
    @outgoing = flags & 2
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
      [
        '<blockquote id="' + @id + '" class="message">'
        "<p>#{@text}</p>"
        '<small><i class="icon-user"></i> '
        @user.name
        ' | ' + feed.formatDate(@date)
        '</small></blockquote>'
        '<div class="clearfix"></div>'
      ].join ' '
    
    $("#user_#{@user.uid} ul.feed").append messageString
