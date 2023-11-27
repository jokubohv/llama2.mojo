FROM ubuntu:22.04

ARG DEFAULT_TZ=America/Los_Angeles
ENV DEFAULT_TZ=$DEFAULT_TZ
ARG MODULAR_HOME=/home/user/.modular
ENV MODULAR_HOME=$MODULAR_HOME

# Update the package list and install Python 3.10 and other necessary packages
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive TZ=$DEFAULT_TZ apt-get install -y \
       tzdata \
       vim \
       sudo \
       curl \
       python3.10 \
       python3.10-venv \
       python3.10-distutils \
       wget \
       gnupg \
       apt-transport-https \
       libedit2

# Create a virtual environment with Python 3.10
ENV VENV_PATH=/home/user/venv
RUN python3.10 -m venv $VENV_PATH

# Activate the virtual environment and upgrade pip
ENV PATH="$VENV_PATH/bin:$PATH"
RUN pip install --upgrade pip

ARG AUTH_KEY=DEFAULT_KEY
ENV AUTH_KEY=$AUTH_KEY

# Install the modular tool and authenticate
RUN apt-get install -y apt-transport-https && \
    keyring_location=/usr/share/keyrings/modular-installer-archive-keyring.gpg && \
    curl -1sLf 'https://dl.modular.com/bBNWiLZX5igwHXeu/installer/gpg.0E4925737A3895AD.key' |  gpg --dearmor >> ${keyring_location} && \
    curl -1sLf 'https://dl.modular.com/bBNWiLZX5igwHXeu/installer/config.deb.txt?distro=debian&codename=wheezy' > /etc/apt/sources.list.d/modular-installer.list && \
    apt-get update && \
    apt-get install -y modular 

RUN modular auth mut_d38276403cbb458c9edd95687b55e4dd && \
    modular install mojo
  
# Add a new user and set the owner of the MODULAR_HOME
RUN useradd -m -u 1000 user \
    && mkdir -p $MODULAR_HOME \
    && chown -R user:user $MODULAR_HOME

# Set the additional PATH for modular tool
ENV PATH="$MODULAR_HOME/pkg/packages.modular.com_mojo/bin:$PATH"

# Install Python packages
RUN pip install \
    jupyterlab \
    ipykernel \
    matplotlib \
    ipywidgets \
    gradio 

# Set the non-root user and working directory
USER user
WORKDIR $HOME/app

# Copy application files and download necessary data
COPY --chown=user . $HOME/app
RUN wget -c  https://huggingface.co/kirp/TinyLlama-1.1B-Chat-v0.2-bin/resolve/main/tok_tl-chat.bin
RUN wget -c  https://huggingface.co/kirp/TinyLlama-1.1B-Chat-v0.2-bin/resolve/main/tl-chat.bin


# Default command to run
CMD ["python3.10", "gradio_app.py"]
