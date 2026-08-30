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
....\space> & 'C:\Program Files\LOVE\love.exe' .
```

### Getting Started Linux
1) Install Love
```
sudo apt update && sudo apt install love
```

2) Run Love

```
love .
```

