# README for Humans

## Getting Started

### Getting started windows
1) Install LOVE   (https://love2d.org/#download)
2) Set up a tasks file for vscode by creating a file .vscode/tasks.json.  Copy the following into it.

```
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Run LOVE Game",
            "type": "shell",
            "command": "C:\\Program Files\\LOVE\\love.exe",
            "args": [
                "${workspaceFolder}"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": []
        }
    ]
}

```

Run love with Ctrl + Shift + B

3) Alternative way to run love is from the powershell command line

```
....\space> & 'C:\Program Files\LOVE\love.exe' . --console
```

**NOTE** - the '--console'  allows print statements to work in powershell

### Getting Started Linux
1) Install Love
```
sudo apt update && sudo apt install love
```

2) Run Love

```
love .
```

3) To get x11 to display back (if running vscode on windows remote to linux)

    - Install vcxsrv (https://sourceforge.net/projects/vcxsrv/)
    - Set up host file like this...

    ```
    Host BasementUbuntu
        HostName 10.0.0.86
        User george
        ForwardAgent yes
        ForwardX11 yes
        ForwardX11Trusted yes
    ```
    - Start VcXsrv using XLaunch desktop icon (to know if its running, check system tray...double click to close it)
    - Connect to remote in vscode

    **NOTE** This failed with response "X connection to localhost:10.0 broken (explicit kill or server shutdown)" when running    $ love .
