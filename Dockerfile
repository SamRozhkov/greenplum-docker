ARG BUILDPLATFORM=${BUILDPLATFORM:-amd64}
FROM --platform=${BUILDPLATFORM} ubuntu:18.04
ARG BUILDKIT_SANDBOX_HOSTNAME=gpdb

WORKDIR /opt

RUN apt-get update

RUN --mount=type=bind,target=bootstrap.sh,src=./docker/bootstrap.sh \
    ./bootstrap.sh

RUN groupadd gpadmin
RUN useradd gpadmin -r -m -g gpadmin
RUN echo "gpadmin:gpadmin" | chpasswd
RUN echo "gpadmin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN chsh gpadmin -s /bin/bash
RUN usermod -a -G sudo gpadmin


RUN apt install -y wget \
    vim
RUN wget https://github.com/pivotal-cf/pivnet-cli/releases/download/v4.1.1/pivnet-linux-amd64-4.1.1

RUN chmod +x pivnet-linux-amd64-4.1.1

RUN ./pivnet-linux-amd64-4.1.1 login --api-token DRAPMzRzLj73JpqFyMrK

RUN ./pivnet-linux-amd64-4.1.1 download-product-files --product-slug='vmware-greenplum' --release-version='6.27.0' --product-file-id=1775959

RUN apt install -y ./greenplum-db-6.27.0-ubuntu18.04-amd64.deb

RUN locale-gen "en_US.UTF-8"
RUN chown -R gpadmin:gpadmin /usr/local/greenplum-db/

RUN mkdir /gpmaster /gpdata1 /gpdata2
RUN chown  gpadmin:gpadmin /gpmaster /gpdata1 /gpdata2

RUN sed -ri 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
RUN sed -ri 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
RUN sed -ri 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config

RUN  ssh-keygen -f /root/.ssh/id_rsa -N '' \
      && mkdir /home/gpadmin/.ssh \
      && cat /root/.ssh/id_rsa.pub >> /home/gpadmin/.ssh/authorized_keys \
      && cp /root/.ssh/id_rsa /root/.ssh/id_rsa.pub /home/gpadmin/.ssh/  \
      && chown gpadmin:gpadmin -R /home/gpadmin/.ssh 

RUN sed -ri 's@^HostKey /etc/ssh/ssh_host_ecdsa_key$@#&@' /etc/ssh/sshd_config
RUN sed -ri 's@^HostKey /etc/ssh/ssh_host_ed25519_key$@#&@' /etc/ssh/sshd_config


RUN mkdir -p /var/run/sshd \
    chmod 0755 /var/run/sshd
#RUN ["/bin/bash", "-c", "/usr/sbin/sshd"]
#CMD ["/usr/bin/sudo", "/usr/sbin/sshd"]

RUN chown gpadmin:gpadmin /etc/ssh/ssh_host_*

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

USER gpadmin

WORKDIR /home/gpadmin

RUN echo "source /usr/local/greenplum-db/greenplum_path.sh" >> ~/.bashrc
RUN echo "export MASTER_DATA_DIRECTORY=/gpmaster/gpsne-1" >> ~/.bashrc

RUN ["/bin/bash"]

RUN cp /usr/local/greenplum-db/docs/cli_help/gpconfigs/gpinitsystem_singlenode ~/

RUN echo $(hostname) >> hostlist_singlenode
RUN sed -i 's/MASTER_HOSTNAME=hostname_of_machine/MASTER_HOSTNAME=$(hostname)/g' gpinitsystem_singlenode
RUN echo 'DATABASE_NAME=adb' >> gpinitsystem_singlenode



#RUN --mount=type=bind,target=initGP.sh,src=./docker/initGP.sh \
#    ./initGP.sh

COPY docker/initGP.sh ./

#RUN ./initGP.sh

#ENTRYPOINT ["~/initGP.sh"]

#RUN /bin/bash  gpinitsystem -c gpinitsystem_singlenode

#RUN bash opt/init.sh