#!/bin/bash

home=`pwd`
kern=/homes/markuze/copy/
func=map_single

cd $kern
cd drivers
#git grep -n $func > $home/tmp/$func.txt
git grep -n $func|cut -d: -f 1|uniq > $home/tmp/$func.txt
