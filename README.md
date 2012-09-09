## Персональный браузерный мессенджер ВКонтакте на WebSocket

### Компиляция фронт-энда

``` sh
$ coffee -cj public/js/main.js public/js/{user,message,users_list,feed,main}.coffee
```

### Запуск

``` sh
$ foreman start
```

и открыть в браузере `public/index.html`.
