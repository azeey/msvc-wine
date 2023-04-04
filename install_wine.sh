dd if=/dev/zero of=ntfs.file bs=1M count=2000 status=progress 
mkfs.ntfs -F --quick $HOME/ntfs.file 
mkdir -p $HOME/.wine
sudo mount -o uid=$(id -u) -o gid=$(id -g) $HOME/ntfs.file $HOME/.wine

# Initialize the wine environment. Wait until the wineserver process has
# exited before closing the session, to avoid corrupting the wine prefix.
wine64 wineboot --init

wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.8.3-Windows-x86_64.exe -O Miniconda3_setup.exe

wine64 Miniconda3_setup.exe /InstallationType=AllUsers /AddToPath=1 /RegisterPython=1 /S /D=z:\\opt\\Miniconda3

# Update conda
wine64 conda install conda -y

#RUN WINEDEBUG=-all wine64 /opt/Miniconda3/Scripts/pip.exe install --no-input -U setuptools
#RUN WINEDEBUG=-all wine64 /opt/Miniconda3/Scripts/pip.exe install --no-input colcon-common-extensions
#RUN WINEDEBUG=-all wine64 /opt/Miniconda3/Scripts/conda.exe install -y cmake curl pkg-config eigen freeimage gts \
#  glib dlfcn-win32 ffmpeg tinyxml2 tinyxml protobuf urdfdom zeromq cppzmq ogre==1.10.12 jsoncpp \
#  libzip qt ninja gdal --channel conda-forge

#RUN WINEDEBUG=-all wine64 /opt/Miniconda3/Scripts/pip.exe uninstall -y colcon-notification
#RUN mkdir /home/$USERNAME/ws 
#WORKDIR /home/$USERNAME/ws
