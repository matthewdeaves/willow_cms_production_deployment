## Nginx Logging Configuration

Logging is a critical component of our Nginx setup for Willow CMS, designed to provide comprehensive insights into server operations while optimizing for containerized environments.

### Custom Log Format

The a custom log format `main_timed` captures detailed information about each request:

[main_timed](https://github.com/matthewdeaves/willow_cms_production_deployment/blob/83002d95c36d4a6566ac8e644b90918d7fcbfb0d/config/nginx/nginx.conf#L15)

```nginx
log_format main_timed '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for" '
                      '$request_time $upstream_response_time $pipe $upstream_cache_status';
```

This format includes:
- Client IP address
- Timestamp
- HTTP request details
- Response status and size
- Referrer and User-Agent information
- Request processing time
- Upstream response time
- Caching status

### Log Destinations

Configuration directs logs to standard output and error streams, which is ideal for containerized environments:

[access_log](https://github.com/matthewdeaves/willow_cms_production_deployment/blob/83002d95c36d4a6566ac8e644b90918d7fcbfb0d/config/nginx/nginx.conf#L20)

```nginx
access_log /dev/stdout main_timed;
error_log /dev/stderr notice;
```

This approach allows for easy integration with container orchestration platforms and log aggregation services, enabling centralized logging and monitoring.

### Error Logging

Error logs are configured at the `warn` level for the Nginx worker processes:

[warn](https://github.com/matthewdeaves/willow_cms_production_deployment/blob/83002d95c36d4a6566ac8e644b90918d7fcbfb0d/config/nginx/nginx.conf#L2)

```nginx
error_log stderr warn;
```

This setting ensures that important error messages are captured without overwhelming the logs with less critical information.

### Benefits of This Logging Setup

1. **Container-Friendly**: By logging to stdout/stderr, we ensure compatibility with container logging drivers and cloud logging services.
2. **Detailed Request Information**: The custom log format provides comprehensive data for each request, aiding in performance analysis and troubleshooting.
3. **Efficient Log Management**: Logging to streams instead of files prevents log rotation issues in containerized environments.
4. **Security Considerations**: The log format includes information useful for security audits, such as client IP addresses and user agents.