Btrfs-progs-btrbk
=================

This is a fork of btrfs-progs, allowing to build distinct binaries for
specific btrfs command groups:

  * btrfs-subvolume-list
  * btrfs-subvolume-show
  * btrfs-subvolume-snapshot
  * btrfs-subvolume-delete
  * btrfs-send
  * btrfs-receive

These binaries are used by btrbk if `backend btrbk-progs-btrbk` is set
in btrbk.conf.

License: GPLv2.


Motivation
----------

While btrfs-progs offer the all-inclusive "btrfs" command, it gets
pretty cumbersome to restrict privileges to the subcommands (command
groups). Common approaches are to either setuid root for "/sbin/btrfs"
(which is not recommended at all), or to write sudo rules for each
command group.
                        
Separating the command groups into distinct binaries makes it easy to
set elevated privileges (capabilities or setuid) on each command
group. A typical use case where this is needed is when it comes to
automated scripts, e.g. btrbk creating snapshots and send/receive them
via ssh.

Installation
------------

After building the binaries (see INSTALL documentation), instead of
`make install`, you have an option to install the binaries along with
elevated file capabilities (setcap) for users in the `btrfs` group:

    $ sudo make install-cap

Or selectively, for installing only a single subcommand:

    $ sudo make install-setcap-btrfs-subvolume-list \
                install-setcap-btrfs-subvolume-show \
                [...]

The result should be something like this:

    $ sudo getcap -r /usr/local/bin/
    /usr/local/bin/btrfs-send = cap_dac_read_search,cap_fowner,cap_sys_admin+ep
    /usr/local/bin/btrfs-receive = cap_chown,cap_dac_override,cap_dac_read_search,cap_fowner,cap_sys_admin,cap_mknod+ep
    /usr/local/bin/btrfs-subvolume-delete = cap_dac_override,cap_sys_admin+ep
    /usr/local/bin/btrfs-subvolume-list = cap_dac_read_search,cap_fowner,cap_sys_admin+ep
    /usr/local/bin/btrfs-subvolume-show = cap_dac_read_search,cap_fowner,cap_sys_admin+ep
    /usr/local/bin/btrfs-subvolume-snapshot = cap_dac_override,cap_dac_read_search,cap_fowner,cap_sys_admin+ep


### Gentoo Linux

If you're on gentoo, grab the digint portage overlay from:
`git://dev.tty0.ch/portage/digint-overlay.git`

Install selected binaries, e.g. for backup source:

    $ echo sys-fs/btrfs-progs-btrbk \
    filecaps \
    btrfs-subvolume-show \
    btrfs-subvolume-list \
    btrfs-send \
    btrfs-subvolume-delete \
    btrfs-subvolume-snapshot >> /etc/portage/package.use

    $ emerge sys-fs/btrfs-progs-btrbk


Development
-----------

If you would like to contribute or have found bugs:

  * Visit the [btrfs-progs-btrbk project page on GitHub] and use the
    [issues tracker] there.
  * Talk to us on Freenode in `#btrbk`.

  [btrfs-progs-btrbk project page on GitHub]: https://github.com/digint/btrfs-progs-btrbk
  [issues tracker]: https://github.com/digint/btrfs-progs-btrbk/issues
             
References
----------

* [btrbk](https://digint.ch/btrbk)
* [btrfs-progs](https://github.com/kdave/btrfs-progs)
