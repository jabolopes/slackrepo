# Create a Slackware 3rd party repository

This project helps you setup your own Slackware 3rd party repository.

This can be useful if you want to build packages to share with others,
or if you want to just build for yourself and you have multiple
computers at home.

This project is pretty much based on the [Slackware repository files
script](http://www.slackware.com/~alien/tools/gen_repos_files.sh) by
Eric "alienbob" Hameleers. So a big kudos to him for writing the
script in the first place. I have only made RSS feed generation
optional because it's not really needed to setup a 3rd party
repository and because it would have required more configuraton.

## Instructions

Instructions on how to use this project to setup a Slackware 3rd party
repository follow.

### Clone this project

Clone this GitHub project and setup an environment variable with its
location.

```shell
git clone git@github.com:jabolopes/slackrepo.git
cd slackrepo
export MYREPO=$(pwd)
```

### Setup your name

Replace the following with your name and email. Follow the same format
because that string will be used to find your PGP key used to sign the
packages.

```
export MYNAME="Jose Lopes <jabolopes@gmail.com>"
```

### Create the packages directory

Create a directory to host the repository's packages.

```shell
mkdir -p "${MYREPO}/slackware"
```

### Create the configuration

Create repository's configuration and make it executable:

```shell
cd "${MYREPO}"
echo REPOSROOT=\"${MYREPO}/slackware\" > genreprc
echo REPOSOWNER=\"${MYNAME}\" >> genreprc
echo RSS=\"no\" >> genreprc
chmod +x genreprc
```

### Generate GPG key to sign packages

Generate a PGP signing key with the following command. Follow the
onscreen instructions and choose, e.g., RSA (sign only), 4096 bits,
put the same name and email address as in $MYNAME and leave the
comment field empty.

```
gpg2 --gen-key
```

### Add packages and generate repository files

For every package that you want to include in the repository, create a
directory for that package with the same name of the package under
"${MYREPO}/slackware", and copy the package to that location, for
example:

```
mkdir "${MYREPO}/slackware/mypackage"
cp mypackage-1.2.3-1_mytag.tgz "${MYREPO}/slackware/mypackage"
...
```

Generate the repository's files (e.g., PACKAGES.txt, FILELIST.txt,
etc):

```shell
cd "${MYREPO}"
./gen_repos_files.sh
```

You can repeat this step multiple times, namely, if you want to add a
new package, simply copy the package to its location and rerun the
previous script.

### Setup HTTP server

Next, we need a distribution mechanism, either HTTP or FTP. Since
Slackware includes the Apache Web Server in the offical distribution,
let's go with that. The following creates a symlink in the web
server's document root. This is NOT THE SAFEST METHOD but it's the
quickest:

```
sudo ln -s ${MYREPO}/slackware /var/www/htdocs/slackware
```

Enable the HTTP server (if it's not already enabled):

```
su -
chmod +x /etc/rc.d/rc.httpd
/etc/rc.d/rc.httpd start
```

Done! The repository should be available under
http://localhost/slackware.
