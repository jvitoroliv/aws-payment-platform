# Base image pinned to specific version — prevents supply chain drift
FROM hashicorp/terraform:1.6.5

RUN mkdir -p /usr/local/share/ca-certificates
# Layer ordering: dependencies first (cacheable), app code last (changes frequently)
COPY caadmin.proxy.example.com.pem /usr/local/share/ca-certificates/proxy-ca.crt
RUN cat /usr/local/share/ca-certificates/proxy-ca.crt >> /etc/ssl/certs/ca-certificates.crt
RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/*

COPY ./terraform_apply.sh /terraform_apply.sh

ENTRYPOINT [""]

CMD ["/terraform_apply.sh"]
