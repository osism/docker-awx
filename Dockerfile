ARG VERSION
ARG VERSION_AWX
ARG RELEASE_CEPH
ARG RELEASE_OPENSTACK

FROM osism/ceph-ansible:$RELEASE_CEPH-$VERSION as ceph-ansible
FROM osism/kolla-ansible:$RELEASE_OPENSTACK-$VERSION as kolla-ansible
FROM osism/osism-ansible:$VERSION as osism-ansible

FROM ansible/awx_web:$VERSION_AWX

USER root

ADD files/playbooks/ceph.yml /var/lib/awx/projects/ceph/site.yml
ADD files/playbooks/generic.yml /var/lib/awx/projects/generic/site.yml
ADD files/playbooks/kolla.yml /var/lib/awx/projects/kolla/site.yml

ADD files/playbooks/awx.yml /opt/ansible/awx.yml

ADD files/surveys /var/lib/awx/surveys

ADD files/requirements.txt /var/lib/awx/venv/requirements.txt
ADD files/run.sh /run.sh
ADD files/initialize.sh /initialize.sh
ADD files/supervisor_initialize.conf /supervisor_initialize.conf

RUN mkdir -p /opt/ansible

COPY --from=ceph-ansible /ansible/ /opt/ansible/ceph/
COPY --from=ceph-ansible /requirements.txt /opt/ansible/ceph/requirements.txt

COPY --from=kolla-ansible /ansible/ /opt/ansible/kolla/
COPY --from=kolla-ansible /requirements.txt /opt/ansible/kolla/requirements.txt

COPY --from=osism-ansible /ansible/ /opt/ansible/osism/
COPY --from=osism-ansible /requirements.txt /opt/ansible/osism/requirements.txt

RUN mv /opt/ansible/ceph/galaxy/* /opt/ansible/ceph/roles \
    && mv /opt/ansible/kolla/galaxy/* /opt/ansible/kolla/roles \
    && mv /opt/ansible/osism/galaxy/* /opt/ansible/osism/roles

RUN chown -R 1000:1000 /opt/ansible

RUN yum -y install cyrus-sasl-devel \
  gcc \
  gcc-c++ \
  krb5-devel \
  libtool-ltdl-devel \
  libxml2-devel \
  libxslt-devel \
  openldap-devel \
  postgresql-devel \
  python36-devel \
  nodejs \
  xmlsec1-devel \
  xmlsec1-openssl-devel

RUN virtualenv -p python3 /var/lib/awx/venv/ceph \
    && /var/lib/awx/venv/ceph/bin/pip install -r /var/lib/awx/venv/requirements.txt \
    && /var/lib/awx/venv/ceph/bin/pip install -r /opt/ansible/ceph/requirements.txt

RUN virtualenv -p python3 /var/lib/awx/venv/kolla \
    && /var/lib/awx/venv/kolla/bin/pip install -r /var/lib/awx/venv/requirements.txt \
    && /var/lib/awx/venv/kolla/bin/pip install -r /opt/ansible/kolla/requirements.txt

RUN virtualenv -p python3 /var/lib/awx/venv/osism \
    && /var/lib/awx/venv/osism/bin/pip install -r /var/lib/awx/venv/requirements.txt \
    && /var/lib/awx/venv/osism/bin/pip install -r /opt/ansible/osism/requirements.txt

RUN yum -y remove cyrus-sasl-devel \
  gcc \
  gcc-c++ \
  krb5-devel \
  libtool-ltdl-devel \
  libxml2-devel \
  libxslt-devel \
  openldap-devel \
  postgresql-devel \
  python36-devel \
  nodejs \
  xmlsec1-devel \
  xmlsec1-openssl-devel

RUN yum -y clean all

RUN pip3 install ansible-tower-cli

USER 1000

VOLUME ["/opt/configuration"]
CMD /run.sh

LABEL "org.opencontainers.image.documentation"="https://docs.osism.io" \
      "org.opencontainers.image.licenses"="ASL 2.0" \
      "org.opencontainers.image.source"="https://github.com/osism/docker-manager" \
      "org.opencontainers.image.url"="https://www.osism.de" \
      "org.opencontainers.image.vendor"="Betacloud Solutions GmbH"
