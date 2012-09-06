window.usersList =
  list: {}
  
  load: (list) ->
    for user_attributes in list
      @list[user_attributes.uid] = new User(user_attributes)
    
    @clearOnLoad()
    @renderMenu()
    @renderPanes()
  
  # очистка и ререндер менюшки
  renderMenu: ->
    # запоминаем активную табу
    activeTabId = $('li.active a').attr('id')
    # чистим меню
    $('#navbar .user').remove()
    
    # наполняем заново
    for id, user of @list
      li = '<li class="user"><a href="#user_' + id + '" id="tab_' + id + '" data-toggle="tab">'
      li += '<i class="icon-user"></i> ' + user.name
      li += ' <span class="label label-success">Online</span>' if user.online
      li += ' <span class="badge badge-warning">' + user.unreadCount() + '</span>' if user.hasUnread()
      li += '</a></li>'
      
      $('#navbar').append li
    
    # восстанавливаем активную табу
    $('#' + activeTabId).parent().addClass('active')
  
  # метод должен вызываться один раз после загрузки usersList
  renderPanes: ->
    for id, user of @list
      pane = '<div class="tab-pane fade user" id="user_' + id + '">'
      pane += '<h6>' + user.name + '</h6><ul class="feed"></ul>'
      pane += '<form class="well message" data-user-id="' + id + '">'
      pane += '<textarea class="span8" name="message" placeholder="Сообщение"></textarea>'
      pane += '<button class="btn btn-primary" type="submit">Отправить</button>'
      pane += '</form></div>'
      
      $('#main').append pane
  
  clearOnLoad: ->
    $('.loading').remove()
