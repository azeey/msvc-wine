FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install -y wine64-development python msitools python-simplejson \
                       python-six ca-certificates && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/msvc

COPY lowercase fixinclude install.sh vsdownload.py ./
COPY wrappers/* ./wrappers/

RUN PYTHONUNBUFFERED=1 ./vsdownload.py --accept-license --dest /opt/msvc && \
    ./install.sh /opt/msvc && \
    rm lowercase fixinclude install.sh vsdownload.py && \
    rm -rf wrappers

RUN apt-get update && \
    apt-get install -y sudo wget p7zip-full vim xvfb
# Add a user with the same user_id as the user outside the container
# Requires a docker build argument `user_id`
ARG user_id=1000
ENV USERNAME developer
RUN useradd -U --uid ${user_id} -m -s /bin/bash $USERNAME \
 && echo "$USERNAME:$USERNAME" | chpasswd \
 && adduser $USERNAME sudo \
 && echo "$USERNAME ALL=NOPASSWD: ALL" >> /etc/sudoers.d/$USERNAME

# Commands below run as the user
RUN chown $USERNAME:$USERNAME /opt
USER $USERNAME

WORKDIR /opt

RUN wget https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-2.7.5-1/rubyinstaller-2.7.5-1-x64.7z \
 && 7z x rubyinstaller-2.7.5-1-x64.7z && mv rubyinstaller-2.7.5-1-x64 ruby27 \
 && rm rubyinstaller-2.7.5-1-x64.7z

# Initialize the wine environment. Wait until the wineserver process has
# exited before closing the session, to avoid corrupting the wine prefix.
RUN wine64 wineboot --init && \
    while pgrep wineserver > /dev/null; do sleep 1; done

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-4.4.10-Windows-x86_64.exe

# Later stages which actually uses MSVC can ideally start a persistent
# wine server like this:
#RUN wineserver -p && \
#    wine64 wineboot && \
RUN sudo dpkg --add-architecture i386 && sudo apt-get update && sudo apt-get install -y wine32-development
RUN xvfb-run wine64 Miniconda3-4.4.10-Windows-x86_64.exe  /InstallationType=JustMe /S /D=z:\\opt\\Miniconda3 &&\
    rm Miniconda3-4.4.10-Windows-x86_64.exe

WORKDIR /home/$USERNAME
COPY wine_env.sh ./
#RUN chown $USERNAME:$USERNAME wine_env.sh

RUN echo 'source $HOME/wine_env.sh' >> /home/$USERNAME/.bashrc
RUN echo 'source $HOME/wine_env.sh' >> /home/$USERNAME/.zshrc

RUN WINEDEBUG=-all wine64 /opt/Miniconda3/Scripts/pip.exe install --no-input -U setuptools
RUN WINEDEBUG=-all wine64 /opt/Miniconda3/Scripts/pip.exe install --no-input colcon-common-extensions
RUN WINEDEBUG=-all wine64 /opt/Miniconda3/Scripts/conda.exe install -y cmake curl pkg-config eigen freeimage gts \
  glib dlfcn-win32 ffmpeg tinyxml2 tinyxml protobuf urdfdom zeromq cppzmq ogre==1.10.12 jsoncpp \
  libzip qt ninja gdal --channel conda-forge

RUN WINEDEBUG=-all wine64 /opt/Miniconda3/Scripts/pip.exe uninstall -y colcon-notification
RUN mkdir /home/$USERNAME/ws 
WORKDIR /home/$USERNAME/ws
