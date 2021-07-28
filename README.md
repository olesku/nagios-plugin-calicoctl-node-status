# nagios-plugin-check-certs ###

Monitors output of ```calicoctl node status``` and alert if any peers has other state than "up".

#### Usage #####
```
Usage:
./check_calicoctl.pl -c <path to calicoctl> [-s] ...

Flags:
-c      <path to calicoctl>     Path to calicoctl binary.
-s      Use sudo.
```

#### Example ####
```
./check_calicoctl.pl -c /usr/local/bin/calicoctl -s
OK: All (9) Calico peers is up.
```

#### Requirements ####

- Perl
- calicoctl