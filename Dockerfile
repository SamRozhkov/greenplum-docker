ARG BUILDPLATFORM=${BUILDPLATFORM:-amd64}
FROM --platform=${BUILDPLATFORM} ubuntu:18.04

WORKDIR /opt

RUN apt-get update

RUN --mount=type=bind,target=bootstrap.sh,src=./docker/bootstrap.sh \
    ./bootstrap.sh

RUN groupadd gpadmin
RUN useradd gpadmin -r -m -g gpadmin
RUN echo "gpadmin:gpadmin" | chpasswd
#RUN usermod -aG wheel gpadmin

RUN apt install -y wget \
    vim
RUN wget https://github.com/pivotal-cf/pivnet-cli/releases/download/v4.1.1/pivnet-linux-amd64-4.1.1

RUN chmod +x pivnet-linux-amd64-4.1.1

RUN ./pivnet-linux-amd64-4.1.1 login --api-token DRAPMzRzLj73JpqFyMrK

RUN ./pivnet-linux-amd64-4.1.1 download-product-files --product-slug='vmware-greenplum' --release-version='6.27.0' --product-file-id=1775959

RUN apt install -y ./greenplum-db-6.27.0-ubuntu18.04-amd64.deb

#RUN source /usr/local/greenplum-db/greenplum_path.sh
RUN cp /usr/local/greenplum-db/docs/cli_help/gpconfigs/gpinitsystem_singlenode /opt

RUN mkdir /gpmaster /gpdata1 /gpdata2
RUN chown  gpadmin:gpadmin /gpmaster /gpdata1 /gpdata2
RUN chown -R gpadmin:gpadmin /usr/local/greenplum-db
RUN chown gpadmin:gpadmin gpinitsystem_singlenode
RUN locale-gen "en_US.UTF-8"
RUN echo 'gpdb' >> hostlist_singlenode
RUN echo 'gpadmin ALL=(ALL) NOPASSWD:/usr/sbin/sshd' >> /etc/sudoers

#RUN bash opt/init.sh