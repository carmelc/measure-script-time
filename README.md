# Measure Script Time
A command line script that allows measuring the execution time of a command line script

##### Installation
1. Clone (or just copy measure.sh)
2. Install the script ```install ./measure.sh /usr/local/bin/measure-script-time```
3. See the manual ```measure-script-time -h```
4. Run it ```measure-script-time -c "npm run lint" -n 2 -r ~/tmp/ -b "git checkout commit-before-change" -a "git checkout master" -l 7```
 - Mac users - better run with caffeinate: ```caffeinate -i measure-script-time -c "npm run lint" -n 2 -r ~/tmp/ -b "git checkout commit-before-change" -a "git checkout master" -l 7``` to avoid machine going into idle

