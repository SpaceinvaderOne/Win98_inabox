FROM alpine:latest

# Install required dependencies needed for the container
RUN apk update && apk upgrade && \
    apk add bash curl qemu-img sed libvirt gawk util-linux libvirt-client coreutils 


WORKDIR /app

# Copy the assets into the container
RUN curl -o /app/kernelex.img https://remotecomputer.co.uk/assets/vdisks/W98/kernelex.img \
    && curl -o /app/normal.img https://remotecomputer.co.uk/assets/vdisks/W98/normal.img \
    && curl -o /app/data.img https://remotecomputer.co.uk/assets/vdisks/W98/data.img

COPY letsgo.sh /app/

# Set permissions
RUN chmod +x /app/letsgo.sh && \
  

# Set  entrypoint
ENTRYPOINT ["/app/letsgo.sh"]

# Sleep for 60 seconds before exiting
CMD ["sh", "-c", "sleep 60"]
