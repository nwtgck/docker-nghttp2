# docker-nghttp2

## Example

```bash
docker pull nwtgck/nghttp2
```

The example below runs an HTTP/3 reverse proxy server on 8443 port forwarding to an existing an HTTP/1.1 server on 8080 port.

```bash
# Create self-signed certificates
(mkdir ssl_certs && cd ssl_certs && openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 365 -sha256 -nodes --subj '/CN=localhost/')

# Run nghttpx for HTTP/3 https://localhost:8443
# (Suppose http://localhost:8080 is running already)
docker run --rm -it -v $PWD/ssl_certs:/shared --privileged \
  -p 8443:8443 \
  -p 8443:8443/udp \
  nwtgck/nghttp2 \
  nghttpx /shared/server.key /shared/server.crt -f '*,8443' -f '*,8443;quic' -b 'localhost,8080'
```

Note that 8443 port is not available when using `--host=net` in `docker run` in Docker Desktop on Mac.
