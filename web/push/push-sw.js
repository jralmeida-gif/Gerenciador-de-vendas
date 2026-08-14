self.addEventListener('push', function (event) {
  var data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch (_) {
    data = { title: 'Gestor de Vendas', body: event.data ? event.data.text() : 'Há um novo lembrete.' };
  }

  var title = data.title || 'Gestor de Vendas';
  var options = {
    body: data.body || 'Há um prazo que precisa da sua atenção.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: data.tag || 'gestor-vendas-prazo',
    renotify: true,
    data: { url: data.url || '/' },
    vibrate: [200, 100, 200]
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var target = event.notification.data && event.notification.data.url
    ? event.notification.data.url
    : '/';

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clients) {
      for (var i = 0; i < clients.length; i++) {
        if ('focus' in clients[i]) {
          clients[i].navigate(target);
          return clients[i].focus();
        }
      }
      return self.clients.openWindow(target);
    })
  );
});
