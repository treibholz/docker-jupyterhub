FROM debian:stretch

ENV DEBIAN_FRONTEND noninteractive

RUN mkdir -p /builddir/
WORKDIR /builddir/

# Install all the stuff we need, Debian has to offer + some tools I just like to have on the terminal
RUN apt-get update && apt-get -y install eatmydata && \
    eatmydata -- apt-get -y dist-upgrade && \
    eatmydata -- apt-get -y install wget locales git bzip2 vim git python3-pip python3-dev python3-pycurl \
        xz-utils libtool libffi-dev ruby ruby-dev make libzmq3-dev libczmq-dev zsh \
        tmux procps exuberant-ctags curl man-db \
        haskell-stack && \
    eatmydata -- /usr/sbin/update-locale LANG=C.UTF-8 && \
    eatmydata -- locale-gen C.UTF-8 && \
    eatmydata -- apt-get remove -y locales && \
    eatmydata -- apt-get clean && \
    eatmydata -- apt-get -y autoremove && \
    eatmydata -- rm -rf /var/lib/apt/lists/*

ENV LANG C.UTF-8

# Install jupyterhub, jupyter, some goodies and the bash_kernel
RUN eatmydata -- pip3 install sqlalchemy tornado jinja2 traitlets requests pycurl nodejs \
    jupyter jupyterhub-ldapauthenticator jupyterhub jupyterhub-tmpauthenticator \
    jupyterhub-ldapcreateusers numpy pandas bash_kernel dockerspawner \
    matplotlib scipy && \
    eatmydata -- python3 -m bash_kernel.install

# Install iRuby kernel
RUN eatmydata -- gem install cztop iruby && \
    eatmydata -- iruby register --force && \
    mv /root/.ipython/kernels/ruby /usr/local/share/jupyter/kernels/

# get NodeJS and install configurable-http-proxy.
# The Debian-Version is much too old and lacks npm.
ENV NODE_JS_VERSION v8.9.4
ENV NODE_JS_SHA256 68b94aac38cd5d87ab79c5b38306e34a20575f31a3ea788d117c20fffcca3370

RUN wget https://nodejs.org/dist/${NODE_JS_VERSION}/node-${NODE_JS_VERSION}-linux-x64.tar.xz && \
    echo "${NODE_JS_SHA256}  node-${NODE_JS_VERSION}-linux-x64.tar.xz" | sha256sum -c - && \
    eatmydata -- tar -Jxf node-${NODE_JS_VERSION}-linux-x64.tar.xz && \
    cp -a node-${NODE_JS_VERSION}-linux-x64/* /usr/local && \
    eatmydata -- npm install -g configurable-http-proxy && \
    eatmydata -- rm -rf /builddir/ ~/.cache ~/.npm ~/.ipython

# get some examples to put in /etc/skel
RUN mkdir -p /etc/skel/notebooks/examples && \
    cd /etc/skel/notebooks/examples && \
    wget -q "https://raw.githubusercontent.com/jupyter/notebook/master/docs/source/examples/Notebook/Running Code.ipynb"\
    "https://raw.githubusercontent.com/jupyter/notebook/master/docs/source/examples/Notebook/Notebook Basics.ipynb"\
    "https://raw.githubusercontent.com/jupyter/notebook/master/docs/source/examples/Notebook/JavaScript Notebook Extensions.ipynb"\
    "https://raw.githubusercontent.com/jupyter/notebook/master/docs/source/examples/Notebook/Custom Keyboard Shortcuts.ipynb"\
    "https://raw.githubusercontent.com/jupyter/notebook/master/docs/source/examples/Notebook/Working With Markdown Cells.ipynb"\
    "https://raw.githubusercontent.com/jupyter/notebook/master/docs/source/examples/Notebook/Importing Notebooks.ipynb"

RUN mkdir -p /srv/jupyterhub/
WORKDIR /srv/jupyterhub/
EXPOSE 8000

LABEL org.jupyter.service="jupyterhub"

CMD ["jupyterhub"]
