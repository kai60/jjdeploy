# JJDeploy

Script to deploy iOS apps (enterprise or adhoc). Archives &amp; exports your app as an ipa, commits and pushes your changes (git &amp; hg), generates an html &amp; uploads everything to a server. It can also optionally send an email when the process finishes correctly.

## Requirements

- The app icon must be in an image asset for the script to be able to correctly find it and use it
- [Transmit](http://panic.com/transmit/) is required to upload the files to a sever, but you can change the script to use a different method.
- *Xcode* & xcodebuild. This script has been tested with Xcode 6.1 (6A1052d), but it should work with older versions of Xcode too.

## What does it do?

This is the process followed by the script, step by step:

1. Creates the archive path
2. Archives your app to a xcarchive file
3. Exports this archive to an ipa file
4. Asks you for a simple description of the changes made
5. Fills the html template file and generates an html file in the archive path
6. Finds the biggest icon in your image assets, and copies it to the archive path as Icon.png
7. If it finds a git or mercurial repository in your project, it will add any changes, commit using your provided changes, and push
8. Uploads the ipa, the html and the icon to your server

## How to use

1. Copy *jjdeploy* and *jjdeploy_resources* to your project folder
2. Open *jjdeploy* and modify the project constants according to your project
3. Open Terminal and run (from the project folder): jjdeploy

## Additional Options

You can run jjdeploy with these parameters:

> *init* (Without any additional parameters: jjdeploy init). Creates a template config file with the name jjdeploy.config in the current directory

> *-v (or --verbose)* will display all the xcodebuild output

> *-email* will send an email with the changes to the company email address in the script

> *--version* Displays the current script version

> *-h* Displays usage instructions

## Creators

- José Manuel Sánchez ([@buscarini](https://twitter.com/buscarini))
- Javier Querol ([@JavierQuerol](https://twitter.com/JavierQuerol))

## License

JJDeploy is released under the MIT license. See LICENSE for details.
