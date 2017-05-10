FROM phusion/baseimage:0.9.19

ENV INSTALL_HOME /opt/application
ENV PROGRAM_NAME ratelimit

RUN mkdir -p $INSTALL_HOME/bin && mkdir -p $INSTALL_HOME/conf/ratelimit

COPY bin/$PROGRAM_NAME $INSTALL_HOME/bin/$PROGRAM_NAME
COPY test/integration/runtime/current/ratelimit/config/*.yaml /opt/application/conf/ratelimit/

RUN chmod +x $INSTALL_HOME/bin/$PROGRAM_NAME

EXPOSE 8080 6070 8081

ENTRYPOINT [ "/opt/application/bin/ratelimit" ]

