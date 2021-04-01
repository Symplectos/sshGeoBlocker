# SSH GeoBlocker with Fail2Ban
The *sshGeoBlocker* bash script uses *geoiplookup* to get the location of an IP address from a [MaxMind](https://www.maxmind.com/en/home) [GeoLite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) database. Combining this script with a fail2ban sshd jail, IP addresses can be blocked after a certain number of unsuccessful connection attempts.

## Installing and Configuring GeoLite2
On Ubuntu, GeoLite2 can be installed with aptitude:

```
sudo apt install geoip-bin geoip-database geoipupdate
```

To enable automatic updates, a free [GeoLite2 Account](https://www.maxmind.com/en/geolite2/signup) is necessary. Once the account is set up, a partially [pre-filled configuration file](https://www.maxmind.com/en/accounts/current/license-key/GeoIP.conf) can be downloaded. Save this file in the */etc* directory as *GeoIP.conf*.

Inside the file, the *YOUR_LICENSE_KEY_HERE* placeholder must be replaced with an actual license key, which can be found on the [account License Keys page](https://www.maxmind.com/en/accounts/current/license-key) of the newly created account.

Finally, to activate automatic updates, a simple cronjob can be defined as follows:

```
0 6 * * 3 /bin/geoipupdate
```

**Note**: MaxMind updates its database every Tuesday.

## Script Configuration
To configure the script, simply set the following two variables:

```bash
# define list of countries that are allowed SSH access (separated by space ; country codes in all caps)
allowedCountries="US CA"

# specify log facility
logFacility="auth.notice"
```

By default, the script logs to */var/log/auth.log* which works well with the standard *fail2ban* *sshd* jail.


## Testing
Before enabling the fail2ban jail, please test if the script works as desired. 

**Note**: The script will not return any visible output to the console, but rather log a *DENY* or *ALLOW* message into the log file specified by the *logFacility* variable.

## Server Configuration
On the server, simply deny all sshd access, by changing the */etc/hosts.deny* file:

```
sshd: ALL
```

Then, using the *etc/hosts.allow* file, enable the script as follows:

```
sshd: ALL: aclexec /pathToScript/sshGeoBlocker.sh %a
```

This tells the system to check the return code of the *./sshGeoBlocker.sh* script to make a decision whether a connection attempt is allowed or denied.

After a while, log messages of the following form should show up in the desired log file, i.e. */var/log/auth*:

```
Apr  1 16:01:49 bell0server root: DENY sshd connection from 221.181.185.135 (CN)
Apr  1 17:11:29 bell0server root: DENY sshd connection from 47.33.161.231 (US)
Apr  1 19:01:58 bell0server root: DENY sshd connection from 142.93.172.19 (DE)
Apr  1 19:02:26 bell0server root: DENY sshd connection from 2a03:b0c0:2:d0::1002:e001 (NL)
```

## Fail2Ban
The above log messages are always followed by a system message like this:

```
Apr  1 19:02:26 bell0server sshd[250966]: refused connect from 2a03:b0c0:2:d0::1002:e001 (2a03:b0c0:2:d0::1002:e001)
```

The standard *sshd* filter of *fail2ban* is already configured to catch those messages:

```
^refused connect from \S+ \(<HOST>\)
```

Thus, by simply enabling an *sshd* jail, connection attempts from non-allowed countries can easily be blocked, for example with the following settings:

```
[sshd]
enabled = true
filter = sshd
maxretry = 3
bantime = 2678400
findtime = 43200
logpath = /var/log/auth.log
```

**Note**: Do not forget to restart the *fail2ban-client*.


## Careful
Please do make sure that a ssh connection to the server is still possible before enabling this script for good!

## References
* [Axllent](https://www.axllent.org/docs/ssh-geoip/)
* [GeoLite2](https://dev.maxmind.com/geoip/geoip2/geolite2/)