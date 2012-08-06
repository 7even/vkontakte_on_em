var usersList = {
  list: [],
  
  load: function(list) {
    this.list = list;
  }
};

$(document).ready(function() {
  ws = new WebSocket("ws://0.0.0.0:8080");
  ws.onmessage = function(evt) {
    $("#debug").append("<pre>" + evt.data + "</pre>");
    
    var message = $.parseJSON(evt.data);
    console.log('received message from server:');
    console.log(message);
    
    if(message.type == 'friends_list') {
      usersList.load(message.data);
    }
  };
  ws.onopen = function() {
    console.log("connected...");
    // ws.send("hello server");
  };
  ws.onclose = function() {
    console.log("socket closed");
  };
});
