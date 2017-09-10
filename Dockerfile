FROM hardware/mailserver:1.1-stable

LABEL description "Simple and full-featured mail server using Docker, with built in Redis Server" \
      maintainer="Malfurious <jmay9990@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y -q redis-server \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/debconf/*-old
RUN mkdir /data && chown -R redis:redis /data
EXPOSE 25 143 465 587 993 4190 11334
COPY run.sh /usr/local/bin
RUN sed -i "s/127.0.0.1/127.0.0.2/g" /etc/redis/redis.conf
RUN sed -i -e 's/\r$//' /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/* /services/*/run /services/.s6-svscan/finish
CMD ["run.sh"]