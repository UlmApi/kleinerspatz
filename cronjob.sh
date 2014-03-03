#!/bin/bash
#this is some script which shall one day become a cron job
#to automatically update the data of the kitas if they have changed
#it should update the kita_final.json and
#push the new data into the repository at github
cd <INSERT PATH HERE>
git pull;
./encodekitas.pl;
while [ $? -ne 0 ]; do sleep 10; ./encodekitas.pl; done;
#execute encodekitas.pl until no errors occur
if [ -n "`git status|grep kita_final.json`" ] #if something has changed
then
  git commit -am "automatic update for kita_final.json from `date +%Y-%m-%d-%H:%M`";
  git push;
fi
