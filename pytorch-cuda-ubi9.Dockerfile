ARG CUDA_VERSION=12.4.1
FROM nvcr.io/nvidia/cuda:${CUDA_VERSION}-devel-ubi9 AS builder
ARG PYTHON_VERSION=3.11
ENV PYTHON=python${PYTHON_VERSION}
ARG VIRTUAL_ENV=/opt/app-root/venv
RUN dnf install -y --nobest --nodocs --setopt=install_weak_deps=False \
        ${PYTHON} ${PYTHON}-devel ${PYTHON}-pip ${PYTHON}-setuptools \
        cmake git-core && \
    dnf clean all && \
    ${PYTHON} -m venv ${VIRTUAL_ENV}

WORKDIR ${VIRTUAL_ENV}
COPY . .

RUN source ${VIRTUAL_ENV}/bin/activate && \
    ${VIRTUAL_ENV}/bin/pip install wheel && \
    ${VIRTUAL_ENV}/bin/pip install pyaml typing_extensions && \
    ${PYTHON} setup.py bdist_wheel

RUN ls -A ${VIRTUAL_ENV}

FROM nvcr.io/nvidia/cuda:${CUDA_VERSION}-runtime-ubi9
ARG CUDA_VERSION=12.4.1

ARG PYTHON_VERSION=3.11
ENV PYTHON=python${PYTHON_VERSION}
RUN export CUDA_DASHED_VERSION=$(echo "${CUDA_VERSION}" | awk -F '.' '{ print $1"-"$2;}') && \
    dnf install -y --nobest --nodocs --setopt=install_weak_deps=False \
        ${PYTHON} ${PYTHON}-pip ${PYTHON}-pip-wheel \
        cuda-cupti-${CUDA_DASHED_VERSION} && \
    dnf clean all

COPY --from=builder /opt/app-root/venv/dist/torch-*.whl /tmp/

RUN ${PYTHON} -m pip install /tmp/*.whl && \
    rm /tmp/*.whl

ENTRYPOINT ["/usr/bin/bash"]
