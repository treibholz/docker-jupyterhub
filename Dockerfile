FROM debian:stretch

ENV DEBIAN_FRONTEND noninteractive

# Install all the stuff we need, Debian has to offer + some tools I just like to have on the terminal
# eatmydata is used to speedup the build
RUN apt-get update && apt-get -y install eatmydata && \
    eatmydata -- apt-get -y dist-upgrade && \
    eatmydata -- apt-get -y install wget locales git bzip2 vim-nox git \
        python3-pip python3-dev python3-pycurl xz-utils libtool libffi-dev \
        ruby ruby-dev make libzmq3-dev libczmq-dev zsh bash-completion tmux procps \
        exuberant-ctags curl man-db python3-tornado python3-sqlalchemy \
        python3-jinja2 python3-requests python3-traitlets python3-matplotlib\
        python3-scipy python3-numpy python3-numpy python3-git python3-pygraphviz\
        luarocks sqlite3 && \
    eatmydata -- /usr/sbin/update-locale LANG=C.UTF-8 && \
    eatmydata -- locale-gen C.UTF-8 && \
    eatmydata -- apt-get remove -y locales && \
    eatmydata -- apt-get clean && \
    eatmydata -- apt-get -y autoremove && \
    eatmydata -- rm -rf /var/lib/apt/lists/*

ENV LANG C.UTF-8

# Install jupyterhub, jupyter, some goodies and the bash_kernel
# jupyter-notebook 5.3.x has a bug https://github.com/jupyter/notebook/issues/3248
RUN eatmydata -- pip3 install \
        nodejs \
        notebook \
        jupyter \
        jupyterhub \
        jupyterhub-ldapauthenticator \
        jupyterhub-ldapcreateusers \
        jupyter-git \
        jupyter_contrib_nbextensions \
        jupyter_nbextensions_configurator \
        ipyparallel \
        bash_kernel && \
    eatmydata -- python3 -m bash_kernel.install && \
    eatmydata -- jupyter-nbextensions_configurator enable && \
    eatmydata -- jupyter contrib nbextension install && \
    eatmydata -- rm -rf ~/.cache ~/.ipython

# Install iRuby kernel
RUN eatmydata -- gem install cztop iruby && \
    eatmydata -- iruby register --force && \
    eatmydata -- mv /root/.ipython/kernels/ruby /usr/local/share/jupyter/kernels/ && \
    eatmydata -- rm -rf ~/.cache ~/.npm ~/.ipython ~/.gem

# get NodeJS and install configurable-http-proxy.
# The Debian-Version is much too old and lacks npm.
ENV NODE_JS_VERSION v8.10.0
ENV NODE_JS_SHA256 92220638d661a43bd0fee2bf478cb283ead6524f231aabccf14c549ebc2bc338


RUN mkdir /node-build/ && cd /node-build/ && \
    eatmydata -- wget -q https://nodejs.org/dist/${NODE_JS_VERSION}/node-${NODE_JS_VERSION}-linux-x64.tar.xz && \
    echo "${NODE_JS_SHA256}  node-${NODE_JS_VERSION}-linux-x64.tar.xz" | sha256sum -c - && \
    eatmydata -- tar -Jxf node-${NODE_JS_VERSION}-linux-x64.tar.xz && \
    eatmydata -- cp -a node-${NODE_JS_VERSION}-linux-x64/* /usr/local && \
    eatmydata -- npm install -g configurable-http-proxy && \
    eatmydata -- rm -rf ~/.cache ~/.npm ~/.ipython /node-build

# get some examples to put in /etc/skel

ENV EXAMPLE_BASE_URL https://raw.githubusercontent.com/jupyter/notebook/master/docs/source/examples/Notebook/
RUN mkdir -p /etc/skel/notebooks/examples && \
    cd /etc/skel/notebooks/examples && \
    wget -q \
        "${EXAMPLE_BASE_URL}/Running Code.ipynb"\
        "${EXAMPLE_BASE_URL}/Notebook Basics.ipynb"\
        "${EXAMPLE_BASE_URL}/JavaScript Notebook Extensions.ipynb"\
        "${EXAMPLE_BASE_URL}/Custom Keyboard Shortcuts.ipynb"\
        "${EXAMPLE_BASE_URL}/Working With Markdown Cells.ipynb"\
        "${EXAMPLE_BASE_URL}/Importing Notebooks.ipynb"

WORKDIR /etc/jupyterhub/
RUN jupyterhub --generate-config -f jupyterhub_config.py

ADD run.sh /

EXPOSE 8000

LABEL org.jupyter.service="jupyterhub"

WORKDIR /srv/jupyterhub/
CMD ["/run.sh"]
