$(document).ready(function() {
  function debug(str) {
    console.log(str);
  };
  
  ws = new WebSocket("ws://0.0.0.0:8080");
  ws.onmessage = function(evt) {
    $("#msg").append("<pre>" + evt.data + "</pre>");
  };
  ws.onopen = function() {
    debug("connected...");
    ws.send("hello server");
  };
  ws.onclose = function() {
    debug("socket closed");
  };
});
