FROM alpine:3.20 AS build

RUN apk add --no-cache git build-base linux-headers

WORKDIR /src
RUN git clone https://github.com/jedisct1/dsvpn.git
WORKDIR /src/dsvpn
# Pin to a known-good commit; bump intentionally after reviewing upstream changes.
RUN git checkout b879839f692e44f0673828cc3afa6ccad31efb86
RUN make

FROM alpine:3.20

RUN apk add --no-cache iproute2 iptables ip6tables ca-certificates

COPY --from=build /src/dsvpn/dsvpn /usr/local/bin/dsvpn

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
