ttrss-on-heroku
=================
Reuben Castelino - projectdelphai@gmail.com

Description
---------------

I originally created an application on [Heroku](http://www.heroku.com) that hosted a [Tiny Tiny RSS](http://tt-rss.org/redmine/projects/tt-rss/wiki) server. I first wrote a post on it [here](http://projectdelphai.github.com/blog/2013/03/15/replacing-google-reader-with-tt-rss-on-heroku/) and left it at that. I knew that not a lot of people would follow through with this project because it required a fair amount of work. Then I stumbled across [this post](http://tt-rss.org/forum/viewtopic.php?f=16&t=1360) on the ttrss forum of a guy that did exactly this but on openshift. So I decided to also make my idea easier to handle and wrote a shell script for it.

I wrote a [second post](http://projectdelphai.github.com/blog/2013/03/23/tt-rss-on-heroku-part-2/) which outlines some bugs, the self-updating process, and some more notes. 

Installation
---------------
Before you start you will need to have installed and set up the [Heroku toolbelt](https://toolbelt.heroku.com/) and [git](http://git-scm.com/downloads). I would strongly recommend that you make sure that you can work with the toolbelt and git so that nothing happens mid-script. Then just place it in a folder where you want to store your local files (to later be uploaded to Heroku) and run it with bash ./ttrss_heroku_setup.sh. Just follow the instruction and hopefully *fingers crossed* it'll work. If anything goes wrong, message me or check my post to see step-by-step instructions. 

Versions
----------------

0.0.3
Upgrade to 1.7.5
Upgrade to 1.7.8

0.0.2
Added environment variables
Self-updates
Query to open in browser
Wget filename specification

0.0.1
Initial commit
