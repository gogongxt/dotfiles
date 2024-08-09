macos() {
  alias updatedb="/usr/libexec/locate.update"

  export LC_ALL=en_US.UTF-8  
  export LANG=en_US.UTF-8



  # header search file path
  export C_INCLUDE_PATH=${C_INCLUDE_PATH}:/opt/homebrew/include/
  export CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}:/opt/homebrew/include/
  # set cmake header path
  export CMAKE_INCLUDE_PATH=${CMAKE_INCLUDE_PATH}:/opt/homebrew/include/
  # compiling lib search file path
  export LIBRARY_PATH=${LIBRARY_PATH}:/opt/homebrew/lib/
  # running lib search file path
  export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/homebrew/lib/

  # add llvm lib
  export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
  export LDFLAGS=" -L/opt/homebrew/opt/Llvm/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
  
  # change c/cxx compile
  export CC="/opt/homebrew/opt/llvm/bin/clang"
  export CXX="/opt/homebrew/opt/llvm/bin/clang++"

  # add openmp lib
  # export LDFLAGS=" -L/opt/homebrew/opt/libomp/lib"
  # export CPPFLAGS="-I/opt/homebrew/opt/libomp/include"}

  # alias gcc="/opt/homebrew/bin/aarch64-apple-darwin23-gcc-14"
  # alias g++="/opt/homebrew/bin/aarch64-apple-darwin23-g++-14"
  # alias clang="/opt/homebrew/bin/aarch64-apple-darwin23-gcc-14"
  # alias clang++="/opt/homebrew/bin/aarch64-apple-darwin23-g++-14"
  # alias ld="/opt/homebrew/bin/"
}

archlinux() {
  #🔽🔽🔽
  # Autostart X at login
  # Ref : https://wiki.archlinux.org/title/Xinit#Autostart_X_at_login
  if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec startx
  fi
  #🔼🔼🔼
  
  # soft ware
  #🔽🔽🔽
  alias clion='nohup /opt/clion/clion-2023.2.1/bin/clion.sh&>/dev/null'
  #🔼🔼🔼
}

ubuntu() {
  
}

if [ -f "/etc/os-release" ]; then
  # Detect whether current is Archlinux
  if [ "$(grep -E '^ID=' /etc/os-release | cut -d'=' -f2)" = "arch" ]; then
      archlinux
  fi
  # Detect whether current is Ubuntu
  if [ "$(grep -E '^ID=' /etc/os-release | cut -d'=' -f2)" = "ubuntu" ]; then
      ubuntu
  fi
fi

# Detect whether current is macos
if [ "$(uname)" = "Darwin" ]; then
  macos
fi
