# docker-nghttp2

[Available Docker tags](https://hub.docker.com/r/nwtgck/nghttp2/tags)

## Example

```bash
docker pull nwtgck/nghttp2
```

The example below runs an HTTP/3 reverse proxy server on 8443 port forwarding to http://example.com.

```bash
# Create self-signed certificates
(mkdir ssl_certs && cd ssl_certs && openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 365 -sha256 -nodes --subj '/CN=localhost/')

# Run nghttpx for HTTP/3 https://localhost:8443 to http://example.com
docker run --rm -it -v $PWD/ssl_certs:/shared --privileged \
  -p 8443:8443 \
  -p 8443:8443/udp \
  nwtgck/nghttp2 \
  nghttpx /shared/server.key /shared/server.crt -f '*,8443' -f '*,8443;quic' -b 'example.com,80'
```

Note that 8443 port is not available when using `--host=net` in `docker run` in Docker Desktop on Mac.
