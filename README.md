**upgrade_mysql** is a simple Bash script using the WHM API to handle MySQL/MariaDB upgrades from the command line. Here's what it looks like:

```
# upgrade_mysql
Heads up! This can be a destructive process. Make sure to run 'backup_mysql' first to create a full backup. Also make a snapshot if this is a VPS.

Installed: MariaDB 10.3

Here's what's available:
* 10.3 [Installed]
* 10.5
* 10.6

Choose Your Fighter (or "Bail"): 10.3

No turning back now. Starting the upgrade...

Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...
Rotating beagles...

Success! MariaDB has been successfully upgraded to 10.3.
```

It repeatedly polls the WHM API for the upgrade status and returns whether it succeeded or failed, and will show the upgrade log and a tail of it in the event of the latter. It should work for both MySQL and MariaDB.

**backup_mysql** is a companion script I wrote. I'm cleaning it up before I put it on GitHub.

## What is a beagle and why is it being rotated?
A beagle is a small dog. We use it as a unit of measurement for how long the upgrade is taking. A single rotation completes in five seconds and on average it takes 25 beagles to rotate before the upgrade is completed.

The actual upgrade process is done in the background with the WHM API, so it's safe if this script is accidentally killed or the SSH connection dies. All this script does is start the upgrade and keep track of it.
