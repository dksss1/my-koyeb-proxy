FROM alpine:3.18

# Устанавливаем Dante (SOCKS) и Python (для веб-сервера)
RUN apk add --no-cache dante-server python3 shadow

# 1. Настраиваем конфигурацию Dante
RUN echo 'logoutput: stderr' > /etc/sockd.conf && \
    echo 'internal: 0.0.0.0 port = 1080' >> /etc/sockd.conf && \
    echo 'external: eth0' >> /etc/sockd.conf && \
    echo 'socksmethod: username' >> /etc/sockd.conf && \
    echo 'user.privileged: root' >> /etc/sockd.conf && \
    echo 'user.unprivileged: sockd' >> /etc/sockd.conf && \
    echo 'client pass { from: 0.0.0.0/0 to: 0.0.0.0/0 }' >> /etc/sockd.conf && \
    echo 'socks pass { from: 0.0.0.0/0 to: 0.0.0.0/0 }' >> /etc/sockd.conf

# 2. Создаем скрипт запуска (через EOF, чтобы не было ошибок сборки)
RUN cat <<'EOF' > /entrypoint.sh
#!/bin/sh
set -e

# Проверка переменных
if [ -z "$PROXY_USER" ] || [ -z "$PROXY_PASSWORD" ]; then
  echo "Error: PROXY_USER and PROXY_PASSWORD are required"
  exit 1
fi

# Создаем пользователя для прокси (если его нет)
id -u $PROXY_USER &>/dev/null || useradd -m -s /bin/sh $PROXY_USER

# Устанавливаем пароль
echo "$PROXY_USER:$PROXY_PASSWORD" | chpasswd

# Запускаем фейковый веб-сервер на порту 8000 (фоном)
mkdir -p /www && echo "Health Check OK" > /www/index.html
python3 -m http.server 8000 --directory /www &

# Запускаем SOCKS сервер (основной процесс)
echo "Starting Dante SOCKS5 server on port 1080..."
exec sockd -f /etc/sockd.conf
EOF

RUN chmod +x /entrypoint.sh

# 3. Открываем порты
EXPOSE 1080 8000

# 4. Команда старта
CMD ["/entrypoint.sh"]
