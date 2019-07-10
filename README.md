# server
A template repo for the actual server.

Create a srv.txt file in the root if this repository and write the name of your server there.

Only 1 line no spaces or special characters. It will be used for filenames and other stuff.

## Setup

```
sudo apt install figlet screen    # On Debian/Ubuntu
sudo yum install figlet screen    # On CentOS/RHEL
sudo dnf install figlet screen    # On Fedora 22+

cd
mkdir -p git && cd git
git clone https://github.com/matricks/bam
cd bam
./make_unix.sh
cd ~/git
git clone --recursive https://github.com/DDNetPP/DDNetPP
git clone https://github.com/chillerbot/chillerbot-fc

cd
git clone https://github.com/DDNetPP/server my_server
cd my_server
echo "my_server" > srv.txt
```

## Run with debugger

```
screen -S my_debug_session
./gdb.sh

# type 'run' and press enter
# ctrl-a ctrl-d to detach

screen -r my_debug_session # to return again on crash or to visit the logs


screen -X -S my_debug_session quit # clean up if you are done
```
