#!/bin/bash -e


: <<'end_long_comment'
    Sets my system up and running.
    If you want to debug it, and stop if there are any errors, use:
    
        bash -ve [script]
end_long_comment



## SCRIPT VARIABLES
BASE_PATH="${BASE_PATH:-/data}"
dpkg -l ubuntu-desktop > /dev/null && IS_DESKTOP=true || IS_DESKTOP=false

MACHINE_TYPE=`uname -m`
[ ${MACHINE_TYPE} == 'x86_64' ] && IS_X86=false || IS_X86=true



## HELPER FUNCTIONS
### ASSURING CONFIGS ARE PRESENT IN A FILE
assure_in_file() {
    local STR FILE
    STR="$1"
    FILE="$2"

    [ -f "$FILE" ] || return 0
    sudo grep -Fxq "$STR" "$FILE" || sudo sh -c "echo \"$STR\" >> \"$FILE\""
}


## CONFIG USED CONFIRMATION
echo 'CONFIGURATION BEING USED:'
$IS_DESKTOP && echo '> DESKTOP ENV' || echo '> SERVER ENV'
$IS_X86 && echo '> 32BIT' || echo '> 64BIT'
read -p "Do you want to continue? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    set -e
else
    echo 'ABORTING...'
    exit
fi
set -v


## PRE-REQUISITES
mkdir -p "${HOME}/tmp"
### APT-ADD-REPOSITORY COMMAND
sudo apt-get install --yes --quiet python-software-properties software-properties-common
### CURL
sudo apt-get install --yes --quiet curl
### SCM
#### CVS
sudo apt-get install --yes --quiet cvs
#### GIT
sudo apt-get install --yes --quiet git
#### MERCURIAL
sudo apt-get install --yes --quiet mercurial

## CONFIGURATIONS
### CREATING BASE DIRECTORY STRUCTURE
sudo mkdir -p "${BASE_PATH}"
sudo chown ${USER}:${USER} "${BASE_PATH}"
mkdir -p "${BASE_PATH}/2b-deleted"
mkdir -p "${BASE_PATH}/2b-synched/2b-organized"
mkdir -p "${BASE_PATH}/2b-synched/bin"
mkdir -p "${BASE_PATH}/2b-synched/music"
mkdir -p "${BASE_PATH}/2b-synched/photos"
mkdir -p "${BASE_PATH}/2b-synched/movies"
mkdir -p "${BASE_PATH}/2b-synched/public"
mkdir -p "${BASE_PATH}/2b-synched/study"
mkdir -p "${BASE_PATH}/2b-synched/vm-data"
mkdir -p "${BASE_PATH}/2b-synched/documents"
mkdir -p "${BASE_PATH}/dev"
mkdir -p "${BASE_PATH}/app"
mkdir -p "${BASE_PATH}/Dropbox"
### SYMLINKING DIRECTORY STRUCTURE
[ -f "${HOME}/Desktop" ] && mv "${HOME}/Desktop" "${HOME}/desktop"
rm -f "${HOME}/app";                    ln -s "${BASE_PATH}/app" "${HOME}/app"
rm -f "${HOME}/dev";                    ln -s "${BASE_PATH}/dev" "${HOME}/dev"
rm -f "${HOME}/2b-deleted";             ln -s "${BASE_PATH}/2b-deleted" "${HOME}/2b-deleted"
rm -f "${HOME}/2b-synched";             ln -s "${BASE_PATH}/2b-synched" "${HOME}/2b-synched"
rm -f "${BASE_PATH}/dropbox";           ln -s "${BASE_PATH}/Dropbox" "${BASE_PATH}/dropbox"
rm -f "${HOME}/dropbox";                ln -s "${BASE_PATH}/dropbox" "${HOME}/dropbox"
# rm -f "${BASE_PATH}/chaosdrop";         ln -s "${BASE_PATH}/.chaosdrop/Dropbox" "${BASE_PATH}/chaosdrop"
# rm -f "${HOME}/chaosdrop";              ln -s "${BASE_PATH}/chaosdrop" "${HOME}/chaosdrop"
### REMOVING UNECESSARY DIRECTORIES
rm -fR "${HOME}/Desktop"
rm -fR "${HOME}/Documents"
rm -fR "${HOME}/Downloads"
rm -fR "${HOME}/Music"
rm -fR "${HOME}/Pictures"
rm -fR "${HOME}/Public"
rm -fR "${HOME}/Templates"
rm -fR "${HOME}/Videos"
rm -f "${HOME}/examples.desktop"
### MAKING CURRENT USER SUDO WITHOUT PASSWORD
assure_in_file "$USER ALL=(ALL) NOPASSWD: ALL" "/etc/sudoers"
### CONFIGURING ENV VARIABLES
assure_in_file "JAVA_HOME=/usr/lib/jvm/java-8-oracle/jre" "/etc/environment"
assure_in_file "EDITOR=vim" "/etc/environment"
### SSH
mkdir -p ~/.ssh
sudo chmod 600 -R "${HOME}/.ssh"
sudo chmod 700 "${HOME}/.ssh"
eval `ssh-agent -s`
ssh-add ~/.ssh/github
### CONFIGURATION MANAGEMENT (mr and vcsh)
sudo rm -fR "${XDG_CONFIG_HOME:-$HOME/.config}/mr"
#sudo rm -fR "${XDG_CONFIG_HOME:-$HOME/.config}/vcsh"
sudo rm -fR "$HOME/.gitignore.d"
sudo rm -f "$HOME/.mrconfig"
sudo apt-get install --yes --quiet mr
CURRDIR=$(pwd)
cd "${BASE_PATH}/app"
sudo rm -fR vcsh
git clone git://github.com/RichiH/vcsh.git vcsh
cd vcsh
sudo rm -f /usr/local/bin/vcsh
sudo ln -s "${BASE_PATH}/app/vcsh/vcsh" /usr/local/bin/vcsh
cd "${CURRDIR}"
### UPDATING DOTFILES (mr and vcsh)
CURRDIR=$(pwd)
cd ~
vcsh clone git@github.com:rhlobo/dotfiles-public.git dotfiles-public || {
    vcsh dotfiles-public pull || vcsh dotfiles-public reset --hard origin/master
}
vcsh clone git@github.com:rhlobo/dotfiles-commons.git dotfiles-commons || {
    vcsh dotfiles-commons pull || vcsh dotfiles-commons reset --hard origin/master
}
#vcsh clone git@github.com:rhlobo/mr-vcsh-profile.git mr || {
#    vcsh run mr git pull || vcsh run mr git pull || echo "Resetting repo"
#    vcsh mr reset --hard
#}
#mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/mr/config.d/"
#cd "${XDG_CONFIG_HOME:-$HOME/.config}/mr/config.d/" && rm -fR ./* && ln -s ../available.d/* .
#mr update
cd "${CURRDIR}"
### SETTING FILE PERMISSIONS
sudo chmod 600 -R "${HOME}/.ssh"
sudo chmod 700 "${HOME}/.ssh"
### UPDATING FONT CACHE
fc-cache -vf ~/.fonts || echo "Not able to update font cache."
### GIT CONFIGS
git config --global push.default simple
git config --global alias.ct commit
git config --global alias.co checkout
git config --global alias.st 'status -sb'
git config --global alias.br branch
git config --global alias.brm 'branch --merged'
git config --global alias.rb rebase
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
git config --global alias.df 'diff --word-diff'
git config --global alias.da 'difftool -d'
git config --global alias.ours '!for i in $(git st --porcelain | grep -e "^UU" | sed -r "s/\S+\s+//g"); do git co --ours -- "$i"; done'
git config --global alias.theirs '!for i in $(git st --porcelain | grep -e "^UU" | sed -r "s/\S+\s+//g"); do git co --theirs -- "$i"; done'
git config --global branch.autosetuprebase always
git config --global help.autocorrect 1
git config --global merge.conflictstyle diff3
git config --global merge.external meld
git config --global color.ui auto
git config --global color.status auto
git config --global color.status.added green
git config --global color.status.modified blue
git config --global color.status.changed yellow
git config --global color.status.untracked white
git config --global color.interactive auto
git config --global color.branch auto
git config --global color.diff always
#git config --global diff.external git-diff-meld
sudo touch /usr/bin/git-diff-meld
sudo sh -c "echo '#!/bin/bash' > /usr/bin/git-diff-meld"
sudo sh -c "echo 'meld $2 $5' > /usr/bin/git-diff-meld"
sudo chmod +x /usr/bin/git-diff-meld


## REPOSITORIES
#### BITTORRENT SYNC
sudo add-apt-repository --yes ppa:tuxpoldo/btsync
#### CANONICAL PARTNER
sudo apt-add-repository --yes "deb http://archive.canonical.com/ $(lsb_release -sc) partner"
#### CRAN (R LANGUAGE)
sudo add-apt-repository --yes ppa:marutter/rrutter
#### EVERNOTE (EVERPAD)
sudo add-apt-repository --yes ppa:nvbn-rm/ppa
#### JAVA (ORACLE)
sudo add-apt-repository --yes ppa:webupd8team/java
#### GOOGLE TALK PLUGIN
sudo sh -c 'echo "deb http://dl.google.com/linux/talkplugin/deb/ stable main" >> /etc/apt/sources.list.d/google-talkplugin.list'
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
#### PIPELINE (WINE SILVERLIGHT) AND NETFLIX (review options vefore activating)
# sudo apt-add-repository --yes ppa:pipelight/stable



## SOFTWARE LISTINGS
sudo apt-get --quiet update


## SOFTWARE
### DEVELOPMENT
#### LATEX
sudo apt-get install --yes --quiet texlive
#sudo apt-get install --yes --quiet texlive-full
sudo apt-get install --yes --quiet texlive-lang-english texlive-lang-portuguese
sudo apt-get install --yes --quiet texlive-science texlive-math-extra
sudo apt-get install --yes --quiet abiword
#### PYTHON
sudo apt-get install --yes --quiet python2.7 python2.7-dev python-setuptools build-essential
sudo apt-get install --yes --quiet ipython ipython-notebook
ipython profile create
#### PYTHON VIRTUALENVWRAPPER
# sudo apt-get install --yes --quiet python-pip
sudo apt-get purge --yes python-pip
cd ~/tmp
wget -O - https://raw.github.com/pypa/pip/master/contrib/get-pip.py
sudo python get-pip.py
cd "${CURRDIR}"
sudo apt-get install --yes --quiet virtualenvwrapper
sudo pip install virtualenvwrapper
#### R
sudo apt-get install --yes --quiet r-base r-base-dev
#### RUBY
#bash -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)
[ ! -f ~/.rvm ] && {
    \curl -L https://get.rvm.io | bash -s stable
    source ~/.rvm/scripts/rvm
    rvm requirements
    rvm install ruby
    rvm use --default ruby
    rvm rubygems current
    gem install rails
}
#### NVM
git clone https://github.com/creationix/nvm.git ~/.nvm && {
    source ~/.nvm/nvm.sh
    nvm install 0.10
    nvm use 0.10 --default
}
#### GO LANG
#sudo apt-get install --yes --quiet bison
#bash < <(curl -s https://raw.github.com/moovweb/gvm/master/binscripts/gvm-installer)
#[ -f ~/.gvm ] && {
#    source ~/.gvm/scripts/gvm
#    gvm install go1.1.1
#    gvm use go1.1.1 --default
#}
sudo apt-get install --yes --quiet golang
#CURRDIR=$(pwd)
#cd ~/app
#wget -O - https://go.googlecode.com/files/go1.2.linux-386.tar.gz | tar xzf -
#cd "${CURRDIR}"
#### ORACLE JAVA JDK 8
sudo apt-get purge --yes --quiet openjdk*
sudo rm -f /var/lib/dpkg/info/oracle-java8-installer*
sudo apt-get purge --yes --quiet oracle-java8-installer*
sudo apt-get --quiet update
sudo apt-get install --yes --quiet oracle-java8-installer
#### MAVEN2
sudo apt-get install --yes --quiet maven2
#### JETTY
sudo apt-get install --yes --quiet jetty
sudo update-rc.d jetty disable


### DEVELOPMENT TOOLS
#### DIFF COLORING
sudo apt-get install --yes --quiet colordiff
#### DOCKER (PETAR)
curl -s https://get.docker.io/ubuntu/ | sudo sh
# sudo apt-get install --yes --quiet docker.io
# ln -sf /usr/bin/docker.io /usr/local/bin/docker
# sed -i '$acomplete -F _docker docker' /etc/bash_completion.d/docker.io
# update-rc.d docker.io defaults
#----- from http://blog.morzproject.com/install-latest-docker-on-ubuntu-14-04/
# sudo sh -c "wget -qO- https://get.docker.io/gpg | apt-key add -"
# sudo sh -c "echo deb http://get.docker.io/ubuntu docker main\ > /etc/apt/sources.list.d/docker.list"
# sudo apt-get --yes --quiet update
# sudo apt-get install --yes --quiet lxc-docker
#----- configs bellow taken from http://patg.net/containers,virtualization,docker/2014/06/09/docker-install/
assure_in_file 'DOCKER_OPTS="--ip=0.0.0.0"' "/etc/defaults/docker"
#assure_in_file 'DOCKER_OPTS="--host=tcp://0.0.0.0:4243”' "/etc/defaults/docker"
#### DOCKER FIG
#sudo bash -c 'curl -L https://github.com/docker/fig/releases/download/0.5.2/linux > /usr/local/bin/fig'
#sudo chmod +x /usr/local/bin/fig
sudo pip install -U fig
#### GITHUB GIT WRAPPER
sudo apt-get install --yes --quiet libyaml-dev
curl http://hub.github.com/standalone -sLo ~/app/hub
#mkdir -p ~/.zsh/completion
#curl https://raw.githubusercontent.com/github/hub/master/etc/hub.zsh_completion -sLo ~/.zsh/completion/hub.zsh_completion
chmod +x ~/app/hub
#### GOOGLE COMMAND LINE TOOLS
sudo apt-get install --yes --quiet googlecl
#### GOOGLE CLOSURE LINTER
sudo easy_install http://closure-linter.googlecode.com/files/closure_linter-latest.tar.gz
#### JQ
#http://stedolan.github.io/jq/download/linux64/jq
CURRDIR=$(pwd) && cd "${HOME}/tmp" && curl http://stedolan.github.io/jq/download/source/jq-1.3.tar.gz | tar xz
cd jq-1.3
./configure && make && sudo make install
cd "${CURRDIR}"
#### NGROK - Expose localhost securely to the world
CURRDIR=$(pwd)
cd ~/app
wget -O ngrok.zip https://api.equinox.io/1/Applications/ap_pJSFC5wQYkAyI0FIVwKYs9h1hW/Updates/Asset/ngrok.zip?os=linux&arch=386&channel=stable
unzip ngrok.zip
rm ngrok.zip
cd "${CURRDIR}"
#### SYNTAX COLORING
sudo apt-get install --yes --quiet source-highlight
#### VIRTUALBOX
sudo apt-get install --yes --quiet virtualbox
#### VAGRANT
sudo apt-get install --yes --quiet vagrant


### PYTHON MISC
#### ANSIBLE
sudo pip install -U ansible
#### ARGH
sudo pip install -U argh
sudo pip install argcomplete
sudo activate-global-python-argcomplete
#### REQUESTS
sudo pip install -U requests
#### TWEEPY (Twitter API Wrapper)
sudo pip install -U tweepy
#### WATCHDOG
sudo apt-get install --yes --quiet libyaml-dev
sudo pip install watchdog

### NETWORK
#### NMAP
sudo apt-get install --yes --quiet nmap

### COMMAND LINE
#### NETHACK
sudo apt-get install --yes --quiet nethack-console
#### ZSH
sudo apt-get install --yes --quiet zsh
#### OH MY ZSH
sudo rm -fR ~/.oh-my-zsh
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
[ ! -f ~/.zshrc ] && cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
chsh -s /bin/zsh
assure_in_file "[ -f ~/.shell_extension ] && . ~/.shell_extension" "${HOME}/.zshrc"
assure_in_file "[ -f ~/.shell_extension ] && . ~/.shell_extension" "${HOME}/.bashrc"
#### SCREEN / BYOBU / TMUX
sudo apt-get install --yes --quiet screen byobu
#### VIM
###### INSTALLING VIM
#sudo apt-get install --yes --quiet vim
###### BUILDING VIM
sudo apt-get install --yes --quiet libncurses5-dev libgnome2-dev libgnomeui-dev libgtk2.0-dev libatk1.0-dev libbonoboui2-dev libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev ruby-dev mercurial
sudo apt-get install --yes --quiet libxtst-dev
for i in $(echo "vim vim-runtime gvim vim-tiny vim-common vim-gui-common"); do sudo apt-get remove --yes --quiet "$i" || "Could not remove $i"; done
CURRDIR=$(pwd)
cd ~/app
sudo rm -Rf vim
hg clone https://code.google.com/p/vim/
cd vim
./configure --with-features=huge \
            --enable-rubyinterp \
            --enable-pythoninterp \
            --with-python-config-dir=/usr/lib/python2.7/config \
            --enable-perlinterp \
            --enable-gui=auto \
            --enable-gtk2-check \
            --enable-gnome-check \
            --with-x \
            --enable-cscope \
            --prefix=/usr
make VIMRUNTIMEDIR=/usr/share/vim/vim74
sudo make install
#sudo apt-get --yes --quiet install checkinstall
#sudo checkinstall
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim 1
sudo update-alternatives --set editor /usr/bin/vim
sudo update-alternatives --install /usr/bin/vi vi /usr/bin/vim 1
sudo update-alternatives --set vi /usr/bin/vim
cd "${CURRDIR}"
###### VIM CONFIGURATIONS
rm -fR "${HOME}/.vimdev"
rm -fR "${HOME}/.vim"
sh <(curl https://raw.github.com/rhlobo/vimdev/master/setup.sh -L)
sudo apt-get install --yes --quiet cmake
sudo apt-get install --yes --quiet python-dev
sudo apt-get install --yes --quiet exuberant-ctags
#sudo add-apt-repository 'deb http://llvm.org/apt/precise/ llvm-toolchain-precise main'
#wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add -
#sudo apt-get --quiet update
#sudo apt-get --yes --quiet install clang-3.5 clang-3.5-doc libclang-common-3.5-dev libclang-3.5-dev libclang1-3.5 libclang1-3.5-dbg libllvm3.5 libllvm3.5-dbg lldb-3.5 llvm-3.5 llvm-3.5-dev llvm-3.5-doc llvm-3.5-runtime clang-format-3.5
cd ~/.vimdev/.vim/bundle/YouCompleteMe || cd ~/.vim/bundle/YouCompleteMe
#bash ./install.sh
bash ./install.sh --clang-completer
#bash ./install.sh --clang-completer --omnisharp-completer
cd "${CURRDIR}"
sudo apt-get install --yes --quiet cabal-install
cabal update
cabal install hdevtools
sudo apt-get install --yes --quiet happy
cabal install ghc-mod
###### VIMPROC (FOR HASKELL SUPPORT)
CURRDIR=$(pwd)
mkdir -p ~/dev/lib-misc
cd ~/dev/lib-misc
rm -Rf vimproc.vim
git clone https://github.com/Shougo/vimproc.vim.git
cd vimproc.vim
make -f make_unix.mak
mkdir -p ~/.vim/bundle/vimproc/autoload
mkdir -p ~/.vim/bundle/vimproc/plugin
cp -r autoload/* ~/.vim/bundle/vimproc/autoload
cp -r plugin/* ~/.vim/bundle/vimproc/plugin
cd ~/.vim/bundle/vimproc/
make -f make_unix.mak
cd "${CURRDIR}"
#### ACK GREP - a tool like grep, optimized for programmers
sudo apt-get install --yes --quiet ack-grep
#### SYSTEM MONITORATION
sudo apt-get install --yes --quiet htop
#### FILESYSTEM NAVIGATION
sudo apt-get install --yes --quiet tree

### COMMON SYSTEM UTILITIES
#### ARCHIVE MANAGEMENT TOOLS
sudo apt-get install --yes --quiet unace unrar zip unzip p7zip-full p7zip-rar sharutils rar uudeview mpack arj cabextract file-roller
#### BITTORRENT SYNC
sudo apt-get --yes --quiet install btsync
#### DROPBOX
CURRDIR=$(pwd)
cd ~
$IS_X86 && {
    wget -O - "https://www.dropbox.com/download?plat=lnx.x86" | tar xzf -
} || {
    wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
}
cd ~/app
wget --no-check-certificate --output-document=dropbox.py "https://www.dropbox.com/download?dl=packages/dropbox.py" && rm -f dropbox && chmod +x dropbox.py && mv dropbox.py dropbox
cd "${CURRDIR}"
    ######## TO EXECUTE
    #~/.dropbox-dist/dropboxd ## to execute it
    ######## TO REGISTER AS SERVICE
    #sudo cp ~/.scripts/system/dropbox_service /etc/init.d/dropbox
    #sudo chmod +x /etc/init.d/dropbox
    #sudo chown root:root /etc/init.d/dropbox
    #sudo update-rc.d dropbox defaults
    #sudo update-rc.d dropbox enable
#### LVM
sudo apt-get install --yes --quiet lvm2 dmeventd
#### MAC CHANGER
sudo apt-get install --yes --quiet macchanger
assure_in_file "/home/rhlobo/.scripts/change_mac_address wlan0 eth0 || true" "/etc/rc.local"
#### MARKDOWN
cd ~/app
wget -O markdown.zip "http://daringfireball.net/projects/downloads/Markdown_1.0.1.zip" && {
    rm -Rf markdown
    rm -Rf Markdown_1.0.1
    unzip markdown.zip
    rm -Rf markdown.zip
    ln -s Markdown_1.0.1 markdown
}
cd "${CURRDIR}"
#### SSHUTTLE
sudo apt-get install --yes --quiet sshuttle
CURRDIR=$(pwd)
cd ~/app
git clone git://github.com/apenwarr/sshuttle
cd "${CURRDIR}"


$IS_DESKTOP && {
    ### DESKTOP CONFIGURATIONS
    sudo groupadd docker || echo 'docker group already exists'
    sudo gpasswd -a rhlobo docker || echo ''
    sudo service docker restart
    ### DESKTOP SYSTEM UTILITIES
    #### ACPI
    sudo apt-get install --yes --quiet acpi
    #### COMMON CODECS
    sudo apt-get install --yes --quiet non-free-codecs || echo "Failed to install 'non-free-codecs'"
    sudo apt-get install --yes --quiet libxine1-ffmpeg || echo "Failed to install 'libxine1-ffmpeg'"
    sudo apt-get install --yes --quiet gxine || echo "Failed to install 'gxine'"
    sudo apt-get install --yes --quiet mencoder || echo "Failed to install 'mencoder'"
    sudo apt-get install --yes --quiet totem-mozilla || echo "Failed to install 'totem-mozilla'"
    sudo apt-get install --yes --quiet icedax || echo "Failed to install 'icedax'"
    sudo apt-get install --yes --quiet tagtool || echo "Failed to install 'tagtool'"
    sudo apt-get install --yes --quiet easytag || echo "Failed to install 'easytag'"
    sudo apt-get install --yes --quiet id3tool || echo "Failed to install 'id3tool'"
    sudo apt-get install --yes --quiet lame || echo "Failed to install 'lame'"
    sudo apt-get install --yes --quiet nautilus-script-audio-convert || echo "Failed to install 'nautilus-script-audio-convert'"
    sudo apt-get install --yes --quiet libmad0 || echo "Failed to install 'libmad0'"
    sudo apt-get install --yes --quiet mpg321 || echo "Failed to install 'mpg321'"
    sudo apt-get install --yes --quiet ubuntu-restricted-extras
    sudo apt-get install --yes --quiet libavcodec-extra
    #### CLIPBOARD FROM THE CLI
    sudo apt-get install --yes --quiet xclip
    #### COMPIZ SETTINGS MANAGER / GNOME AND UNITY TWEAKS
    sudo apt-get install --yes --quiet compiz-plugins-extra compizconfig-settings-manager
    sudo apt-get install --yes --quiet gnome-tweak-tool
    sudo apt-get install --yes --quiet unity-tweak-tool
    #### CPU FREQ
    sudo apt-get install --yes --quiet indicator-cpufreq
    #### CUPS PDF (Print PDF files)
    sudo apt-get install --yes --quiet cups-pdf
    #### ESPEAK (reads text from command line)
    sudo apt-get install --yes --quiet espeak
    #### GLIPPER (CLIPBOARD HISTORY - Alt+V)
    sudo apt-get install --yes --quiet glipper
    #### JAVA INTEGRATION WITH UNITY HUD
    sudo add-apt-repository --yes ppa:danjaredg/jayatana
    sudo apt-get --quiet update
    sudo apt-get install --yes --quiet jayatana
    #### LINRUNNER (BATTERY LIFE)
    sudo add-apt-repository --yes ppa:linrunner/tlp
    sudo apt-get --quiet update
    sudo apt-get --yes --quiet install tlp tlp-rdw
    sudo tlp start
    #### MAC CHANGER
    sudo apt-get install --yes --quiet macchanger-gtk
    #### NETFLIX (see http://www.omgubuntu.co.uk/2014/08/netflix-linux-html5-support-plugins)
    ## Should install chrome >= 037, plus run netflix as another browser for DRM
    # sudo apt-get install --yes --quiet pipelight-multi
    # sudo pipelight-plugin --enable silverlight
    # sudo apt-get install --yes --quiet netflix-desktop
    #### PAM AUTH (USB)
    sudo apt-get install --yes --quiet libpam-usb
    sudo apt-get install --yes --quiet pamusb-tools
    ###### CONFIGURING (MANUAL)
    #   sudo pamusb-conf --add-device <my-usb-stick>
    #   sudo pamusb-conf --add-user <ubuntu-user>
    #   sudo vi /etc/pam.d/common-auth
    #       Add:
    #       auth    sufficient      pam_usb.so
    #   sudo vi /etc/pamusb.conf
    #       Modify:
    #       <user id="ubuntu-user">
    #             <device>
    #                     my-usb-stick
    #             </device>
    #             <agent event="lock">gnome-screensaver-command -l</agent>
    #             <agent event="unlock">gnome-screensaver-command -d</agent>
    #        </user>
    #   Execute pamusb-agent
    #### POWER MANAGEMENT
    $IS_X86 && {
        sudo apt-get install --yes --quiet hal
    } || {
        sudo apt-get install --yes --quiet hal-info
    }
    sudo apt-get install --yes --quiet powermanagement-interface
    #### SHUTTER SCREENSHOT
    sudo apt-get install --yes --quiet shutter
    #### TOUCHPAD INDICATOR
    sudo add-apt-repository --yes ppa:atareao/atareao
    sudo apt-get --quiet update
    sudo apt-get install --yes --quiet touchpad-indicator
    #### UBUNTU NOTIFICATIONS
    sudo apt-get install --yes --quiet notify-osd
    #### UBUNTU AUTOMATION THROUGH CL (xte 'key Page_Up'; xte 'mousecick buttonNumber'; xte 'keydown Super_L')
    sudo apt-get install --yes --quiet xautomation xdotool
    #### XBACKLIGHT
    # Freezes computer when discrete video card is off
    # sudo apt-get install --yes --quiet xbacklight

    ### DESKTOP APPLICATIONS
    #### BITTORRENT SYNC
    sudo apt-get --yes --quiet install btsync-user
    #### DROPBOX
    CURRDIR=$(pwd)
    cd "${HOME}/tmp"
    $IS_X86 && wget --no-check-certificate --output-document=dropbox.deb https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_1.6.0_i386.deb || wget --no-check-certificate --output-document=dropbox.deb https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_1.6.0_amd64.deb
    sudo dpkg -i dropbox.deb
    rm -f dropbox.deb
    cd "${CURRDIR}"
    #### EVERNOTE (EVERPAD)
    sudo apt-get install --yes --quiet everpad
    #### FREEMIND
    sudo apt-get install --yes --quiet freemind
    #### GOOGLE CHROME
    CURRDIR=$(pwd)
    cd "${HOME}/tmp"
    sudo apt-get install --yes --quiet libcurl3 libnspr4-0d libgconf2-4 libxss1
    $IS_X86 && wget --no-check-certificate --output-document=google-chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_i386.deb" || wget --no-check-certificate --output-document=google-chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    sudo dpkg -i google-chrome.deb
    rm -f google-chrome.deb
    cd "${CURRDIR}"
    #### GOOGLE TALK PLUGIN
    sudo apt-get install --yes --quiet google-talkplugin
    #### GUAKE
    sudo apt-get install --yes --quiet guake
    #### MELD DIFF VIEWER
    sudo apt-get install --yes --quiet meld
    #### POP CORN (popcorn.cdnjd.com / http://popcorn-time.tv)
    CURRDIR=$(pwd)
    rm -Rf ~/app/popcorn
    mkdir -p ~/app/popcorn
    cd ~/app/popcorn
    curl http://time4popcorn.eu/Popcorn-Time-linux64.tar.gz | tar xz
    sudo apt-get install --yes --quiet libudev1:i386
    sudo ln -sf /lib/$(arch)-linux-gnu/libudev.so.1 /lib/$(arch)-linux-gnu/libudev.so.0
    cd "${CURRDIR}"
    #### RXVT-UNICODE TERMINAL EMULATOR (EXPERIMENTAL)
    #sudo apt-get install --yes --quiet rxvt-unicode-256color ncurses-term
    sudo apt-get install --yes --quiet rxvt-unicode
    #### REMINDOR - ALARM NOTIFICATIONS
    sudo add-apt-repository --yes ppa:bhdouglass/indicator-remindor
    sudo apt-get --quiet update
    sudo apt-get install --yes --quiet indicator-remindor
    #### SKYPE
    sudo apt-get install --yes --quiet skype
    sudo apt-get install --yes --quiet sni-qt:i386
    #### SUBTITLE EDITOR
    sudo apt-get install --yes --quiet subtitleeditor
    #### TRUECRYPT
    sudo add-apt-repository --yes ppa:stefansundin/truecrypt
    sudo apt-get --quiet update
    sudo apt-get install --yes --quiet truecrypt
    #### VIDEO CONVERSION
    sudo apt-get install --yes --quiet transmageddon
    sudo apt-get install --yes --quiet mencoder # mencoder input.mp4 -vop scale=640:480 -o output.mp4
    sudo apt-get install --yes --quiet libav-tools # avconv -i input.mp4 -s 640x480 output.mp4
    #http://www.miksoft.net/products/mmc_1.8.4_i386.deb
    #### VLC
    sudo apt-get install --yes --quiet vlc
    ##### VlSub
    CURRDIR=$(pwd)
    cd "${HOME}/tmp"
    sudo rm -Rf vlsub
    git clone https://github.com/exebetche/vlsub.git
    mkdir -p ~/.local/share/vlc/lua/extensions/
    cp vlsub/vlsub.lua ~/.local/share/vlc/lua/extensions/vlsub.lua
    cd "${CURRDIR}"

    ### XMONAD
    #### XMONAD
    sudo apt-get install --yes --quiet gnome-panel
    sudo apt-get install --yes --quiet xmonad
    $IS_X86 && {
        sudo apt-get install --yes --quiet libghc6-xmonad-contrib-dev
    } || {
        sudo apt-get install --yes --quiet libghc-xmonad-contrib-dev
    }
    
    mkdir -p ~/.xmonad
    touch ~/.xmonad/xmonad.hs
    #### FEH (background image)
    sudo apt-get install --yes --quiet feh
    #### WINDOW EFFECTS (transparency??)
    sudo apt-get install --yes --quiet xcompmgr
    $IS_X86 && {
        sudo apt-get install --yes --quiet transset
    } || {
        sudo apt-get install --yes --quiet x11-apps
    } 
    #### MINIMALISTIC PDF VIEWER
    sudo apt-get install --yes --quiet zathura
    #### COREUTILS (DIRCOLORS)
    sudo apt-get install --yes --quiet coreutils
    #### DZEN2 BAR
    sudo apt-get install --yes --quiet dzen2
    #### CONKY
    sudo apt-get install --yes --quiet conky
}


## UPDATING SYSTEM
sudo apt-get --quiet update
sudo apt-get --yes --quiet upgrade


## FINALIZING SETUP
sudo rm -fR "${HOME}/tmp"
sudo chmod 600 -R "${HOME}/.ssh"
sudo chmod 700 "${HOME}/.ssh"


gsettings set com.canonical.Unity.Lenses disabled-scopes "['more_suggestions-amazon.scope', 'more_suggestions-u1ms.scope', 'more_suggestions-populartracks.scope', 'music-musicstore.scope', 'more_suggestions-ebay.scope', 'more_suggestions-ubuntushop.scope', 'more_suggestions-skimlinks.scope']"

exit 0


###############################################################################
# EXPERIMENTAL



#gtk2+ themes
sudo apt-get install lxappearance

sudo add-apt-repository ppa:moka/stable
sudo apt-get update
sudo apt-get install orchis-gtk-theme

sudo add-apt-repository ppa:numix/ppa
sudo apt-get update && sudo apt-get install numix-gtk-theme


#http://www.webupd8.org/2013/09/adobe-flash-player-hardware.html
#https://github.com/i-rinat/libvdpau-va-gl


## Bublebee
sudo add-apt-repository --yes ppa:bumblebee/stable
sudo apt-get --quiet update
sudo apt-get --quiet update
#### 12.04 Full-install
#sudo apt-get install --yes --quiet bumblebee bumblebee-nvidia virtualgl linux-headers-generic
#### 13.10 Full-install
#sudo apt-get install --yes --quiet bumblebee bumblebee-nvidia primus linux-headers-generic
#### Minimal setup (power saving only, not the power savings)
sudo apt-get install --yes --quiet --no-install-recommends bumblebee
sudo apt-get install --yes --quiet virtualgl
sudo apt-get install --yes --quiet primus
#### 64 BIT
#sudo apt-get install --yes --quiet virtualgl-libs-ia32 primus-libs-ia32
#### Follow these instructions:
https://github.com/Bumblebee-Project/bbswitch


## VMWARE
CURRDIR=$(pwd)
sudo apt-get install --yes --quiet gcc
sudo apt-get install --yes --quiet linux-headers-generic
cd /lib/modules/$(uname -r)/build/include/linux
sudo ln -s ../generated/utsrelease.h
sudo ln -s ../generated/autoconf.h
sudo ln -s ../generated/uapi/linux/version.h
cd "${HOME}/2b-synched/bin/vmware9"
sudo ./VMware-Workstation-Full-9.0.1-894247.i386.sh
sudo vmware-modconfig --console --install-all
cd "${CURRDIR}"


## RTL8111/8168/8411 PCI Express Gigabit Ethernet
sudo apt-get install linux-headers-generic build-essential dkms
wget http://ftp.de.debian.org/debian/pool/main/r/r8168/r8168-dkms_8.039.00-1_all.deb
sudo dpkg -i r8168*.deb
echo "# map the specific PCI IDs instead of blacklisting the whole r8169 module" | sudo tee -a /etc/modprobe.d/r8168-dkms.conf
echo -e "alias\tpci:v00001186d00004300sv00001186sd00004B10bc*sc*i*\tr8168" | sudo tee -a /etc/modprobe.d/r8168-dkms.conf
echo -e "alias\tpci:v000010ECd00008168sv*sd*bc*sc*i*\t\t\tr8168" | sudo tee -a /etc/modprobe.d/r8168-dkms.conf
#echo "blacklist r8169" | sudo tee -a /etc/modprobe.d/blacklist-r8169.conf
sudo modprobe -rfv r8169
sudo modprobe -v r8168
sudo service network-manager restart


## Atheros AR8161 Ethernet
sudo apt-get install build-essential linux-headers-generic linux-headers-`uname -r`
CURRDIR=$(pwd) && mkdir -p "${HOME}/tmp" && cd "${HOME}/tmp" && wget -O - http://linuxwireless.org/download/compat-wireless-2.6/compat-wireless-2012-07-03-pc.tar.bz2 | tar -xj
cd compat-wireless-2012-07-03-pc
./scripts/driver-select alx
make
sudo make install
cd "${CURRDIR}"
sudo rm -R "${HOME}/tmp"
#---- OR ----
sudo apt-get install linux-backports-modules-cw-3.4-precise-generic
sudo modprobe alx


## UBUNTU AS BLUETOOTH KEYBOARD
sudo apt-get install libbluetooth-dev
CURRDIR=$(pwd) && mkdir -p "${HOME}/tmp" && cd "${HOME}/tmp" && wget -0- http://anselm.hoffmeister.be/computer/hidclient/hidclient-20120728.tar.bz2 | tar xjf
gcc -o hidclient hidclient.c -O2 -lbluetooth -Wall
make
sudo cp /etc/bluetooth/main.conf /etc/bluetooth/main.conf.bkp
# sudo vi /etc/bluetooth/main.conf
# • Under #DisablePlugins = network,input add the line DisablePlugins = input (no #).
# • Add a # to the beginning of Class = 0x000100; under it, write Class=0x000540 (no #).
sudo rm -R "${HOME}/tmp"
cd "${CURRDIR}"


## Ubuntu as DLNA server (https://help.ubuntu.com/community/MiniDLNA)
sudo apt-get install --yes --quiet minidlna
sudo sh -c 'echo "#network_interface=wlan0" > /etc/minidlna.conf'
sudo sh -c 'echo "media_dir=A,/data/2b-synched/music" >> /etc/minidlna.conf'
sudo sh -c 'echo "media_dir=P,/data/2b-synched/photos" >> /etc/minidlna.conf'
sudo sh -c 'echo "media_dir=V,/data/2b-synched/movies" >> /etc/minidlna.conf'
sudo sh -c 'echo "friendly_name=UbuntuMiniDLNA" >> /etc/minidlna.conf'
sudo sh -c 'echo "db_dir=/var/cache/minidlna" >> /etc/minidlna.conf'
sudo sh -c 'echo "log_dir=/var/log" >> /etc/minidlna.conf'
sudo sh -c 'echo "inotify=yes" >> /etc/minidlna.conf'
sudo sh -c 'echo "notify_interval=900" >> /etc/minidlna.conf'
sudo sh -c 'echo "port=8200" >> /etc/minidlna.conf'
sudo sh -c 'echo "serial=12345678" >> /etc/minidlna.conf'
sudo sh -c 'echo "model_number=1" >> /etc/minidlna.conf'
sudo sh -c 'echo "enable_tivo=no" >> /etc/minidlna.conf'
sudo mkdir -p /var/cache/minidlna
sudo service minidlna restart
sudo service minidlna force-reload


### WINE
sudo apt-get autoremove wine --purge
rm -Rf ~/.wine
rm -Rf ~/.wine-TEMPLATE
sudo add-apt-repository --yes ppa:ubuntu-wine/ppa
sudo apt-get --quiet update && sudo apt-get install --yes --quiet wine
#winetricks d3dx9 droid winxp sound=alsa volnum vcrun2008 corefonts
winetricks d3dx9 droid winxp vcrun2008 corefonts
cp -R .wine .wine-TEMPLATE


### IRSSI & BITLBEE
sudo apt-get install --yes --quiet irssi irssi-scripts


### FINGERPRINT - not ready for production, patch is needed, pull request pending
sudo apt-add-repository --yes ppa:fingerprint/fingerprint-gui && sudo apt-get --quiet update
sudo apt-get install --yes --quiet libbsapi policykit-1-fingerprint-gui fingerprint-gui
sudo apt-get install libperl-dev libgtk2.0-dev libusb-1.0-0-dev libnss3-dev
sudo apt-get install libxv-dev
wget https://github.com/ars3niy/fprint_vfs5011/archive/master.zip
unzip ./master.zip
cd ./fprint_vfs5011-master
./autogen.sh
./configure
make
sudo make install
sudo apt-get install fprint-demo fprintd fprintd-doc libfprint0
sudo fprint_demo
