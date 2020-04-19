FROM docker.elastic.co/beats/filebeat:6.5.4

# copy config
COPY ./filebeat.yml /usr/share/filebeat/filebeat.yml
COPY ./nginx.yml /usr/share/filebeat/modules.d/nginx.yml
COPY ./default.json /usr/share/filebeat/module/nginx/access/ingest/default.json

USER root
RUN chown root:filebeat /usr/share/filebeat/filebeat.yml
RUN chown root:filebeat /usr/share/filebeat/modules.d/nginx.yml
RUN chown root:filebeat /usr/share/filebeat/module/nginx/access/ingest/default.json

USER filebeat
