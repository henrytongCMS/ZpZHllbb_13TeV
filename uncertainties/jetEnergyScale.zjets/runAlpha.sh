#!/bin/sh

source /afs/cern.ch/sw/lcg/external/gcc/4.9/x86_64-slc6-gcc49-opt/setup.sh
source /afs/cern.ch/sw/lcg/app/releases/ROOT/6.04.10/x86_64-slc6-gcc49-opt/root/bin/thisroot.sh

channel=(ele mu)
cat=(1 2)

for ((i=0; i<${#channel[@]}; i++)); do
    for ((j=0; j<${#cat[@]}; j++)); do
	echo "Now running ==> channel: " ${channel[$i]} " category: " ${cat[$j]}
	root -q -b -l getAlphaUnc.C\(\"${channel[$i]}\"\,\"${cat[$j]}\"\)
    done
done

mkdir alphaJetEnScaleResults/
mv *pdf alphaJetEnScaleResults/
rm -rf $HOME/www/alphaJetEnScaleResults/
mv alphaJetEnScaleResults/ $HOME/www/

mkdir background_JES_root
mv *.root background_JES_root

echo "All the jobs are finished."

exit
