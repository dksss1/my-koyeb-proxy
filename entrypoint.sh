#!/bin/sh
set -e

# Создаём пользователя для SOCKS5 (если ещё нет)
if ! id "$PROXY_USER" >/dev/null 2>&1; then
  useradd -m "$PROXY_USER"
  echo "$PROXY_USER:$PROXY_PASSWORD" | chpasswd
fi

# Запускаем Dante (SOCKS5) в фоне
danted -f /etc/danted.conf

# Запускаем Privoxy (HTTP-прокси) как основной процесс
exec privoxy --no-daemon /etc/privoxy/config
