FROM alpine:latest

# Install required dependencies needed for the container
RUN apk update && apk upgrade && \
    apk add bash curl qemu-img sed libvirt gawk util-linux libvirt-client coreutils 

# Set working directory here
WORKDIR /app

# Download the disk images
RUN curl -o /app/kernelex.img https://remotecomputer.co.uk/assets/vdisks/W98/kernelex.img \
    && curl -o /app/normal.img https://remotecomputer.co.uk/assets/vdisks/W98/normal.img \
    && curl -o /app/data.img https://remotecomputer.co.uk/assets/vdisks/W98/data.img

# Copy the assets into the container
COPY letsgo.sh /app/
COPY w98.xml /app/

# Set permissions
RUN chmod +x /app/letsgo.sh && \
    chmod 644 /app/w98.xml

# Run the letsgo.sh script in the background and sleep indefinitely
CMD ["sh", "-c", "/app/letsgo.sh & sleep infinity"]
