# Docker container for JDownloader 2
[![Build Status](https://cloud.drone.io/api/badges/baldator/docker-jdownloader-2/status.svg)](https://cloud.drone.io/baldator/docker-jdownloader-2)

This is a Docker container for [JDownloader 2](http://jdownloader.org/).

The GUI of the application is accessed through a modern web browser (no installation or configuration needed on client side) or via any VNC client.

---

[![JDownloader 2 logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/jdownloader-2-icon.png&w=200)](http://jdownloader.org/)[![JDownloader 2](https://dummyimage.com/400x110/ffffff/575757&text=JDownloader+2)](http://jdownloader.org/)

JDownloader 2 is a free, open-source download management tool with a huge
community of developers that makes downloading as easy and fast as it should be.
Users can start, stop or pause downloads, set bandwith limitations, auto-extract
archives and much more. It's an easy-to-extend framework that can save hours of
your valuable time every day!

---

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the JDownloader 2 docker container with the following command:
```
docker run -d \
    --name=jdownloader-2 \
    -p 5800:5800 \
    -v /docker/appdata/jdownloader-2:/config:rw \
    -v $HOME/Downloads:/output:rw \
    baldator/jdownloader-2
```

Where:
  - `/docker/appdata/jdownloader-2`: This is where the application stores its configuration, log and any files needing persistency.
  - `$HOME/Downloads`: This is where downloaded files are stored.

Browse to `http://your-host-ip:5800` to access the JDownloader 2 GUI.

## Documentation

Full documentation is available at https://github.com/baldator/docker-jdownloader-2.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://baldator.github.io/docker-apps.

[create a new issue]: https://github.com/baldator/docker-jdownloader-2/issues
