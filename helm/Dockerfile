FROM registry.redhat.io/openshift4/ose-cli:latest
RUN dnf install -y jq
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
ADD inference-0.1.0.tgz inference-0.1.0.tgz
ADD inference inference
ADD start.sh start.sh
RUN chmod 750 start.sh
CMD ./start.sh
