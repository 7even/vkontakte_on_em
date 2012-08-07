$(document).ready(function() {
  var navbar = $('#navbar');
  var main = $('#main');
  
  var usersList = {
    list: [],
    
    load: function(list) {
      this.list = list;
      this.render();
    },
    
    render: function() {
      navbar.empty();
      main.empty();
      this.renderTab('debug', 'Debug info', true);
      
      $(this.list).each(function(index, user) {
        var id = 'user' + user.uid;
        var name = user.first_name + ' ' + user.last_name;
        usersList.renderTab(id, name);
      });
    },
    
    renderTab: function(id, name, active) {
      if(active == null) active = false;
      
      var li = '<li' + (active ? ' class="active"' : '') + '><a href="#' + id + '" data-toggle="tab">' + name + '</a></li>'
      var pane = '<div class="tab-pane' + (active ? ' active' : '') + '" id="' + id + '"><h6>' + name + '</h6></div>';
      
      navbar.append(li);
      main.append(pane);
    }
  };
  
  ws = new WebSocket("ws://0.0.0.0:8080");
  ws.onmessage = function(evt) {
    var message = $.parseJSON(evt.data);
    console.log('received message from server:');
    console.log(message);
    
    if(message.type == 'friends_list') {
      usersList.load(message.data);
    }
    
    $("#debug").append("<pre>" + evt.data + "</pre>");
  };
  ws.onopen = function() {
    console.log("connected...");
    // ws.send("hello server");
  };
  ws.onclose = function() {
    console.log("socket closed");
  };
});
