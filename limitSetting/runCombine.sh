#!/bin/sh

pwd=$PWD
cmsswdr=/afs/cern.ch/work/h/htong/CMSSW_7_1_5/src

## do cmsenv ##

cd $cmsswdr
export SCRAM_ARCH=slc6_amd64_gcc481
eval `scramv1 runtime -sh`
cd $pwd

CHAN=(ele mu)
BTAG=(1 2)
mass=(800 1000 1200 1400 1600 1800 2000 2500 3000 3500 4000)

## generate the necessary text file (contain event numbers) and root file (contain hist of ZH mass) ##

for ((i=0; i<${#CHAN[@]}; i++)); do
    for ((j=0; j<${#BTAG[@]}; j++)); do

	printf "\E[1;32m"
	echo -e "*** Generate the necessary text file and root file ***"
	printf "\E[0m"
	
	outroot=mZH${CHAN[$i]}btag${BTAG[$j]}.root
	textfile=nEv${CHAN[$i]}btag${BTAG[$j]}.txt

	root -q -b -l nZHplots.C\(\"${CHAN[$i]}\"\,\"${BTAG[$j]}\"\,\"$outroot\"\,\"$textfile\"\)

	rootfile=input_${CHAN[$i]}_cat${BTAG[$j]}.root

        ## combine the shape histograms together with distibution histogram

	printf "\E[1;32m"
	echo -e "*** Combine root files to a single file ***"
	printf "\E[0m"

	hadd $rootfile $outroot systUncOnShapes/*/*_${CHAN[$i]}_cat${BTAG[$j]}.root
	
        ## make data cards for the combine tool ##
	
	dataCarddr=dataCards${CHAN[$i]}btag${BTAG[$j]}
	
	mkdir -p $dataCarddr
	
	printf "\E[1;32m"
	echo -e "*** Make data cards for the combine tool by using: " $textfile " ***"
	echo -e "*** Data cards move to: " $dataCarddr " ***"
	printf "\E[0m"

	signaluncfile=systUncOnSigEff/${CHAN[$i]}_${BTAG[$j]}btag_systUncOnSigEff.txt
	otheruncfile=systUncOnOthers/${CHAN[$i]}_${BTAG[$j]}btag_otherSystUnc.txt

	python MakeDataCards.py $textfile $rootfile $signaluncfile $otheruncfile ./$dataCarddr
	
	rm -f DataCard_MXXXGeV.txt
	mv $rootfile $dataCarddr

        ## use the combine tool ##

	cd $cmsswdr/HiggsAnalysis/CombinedLimit/src
	
	for ((k=0; k<${#mass[@]}; k++)); do
	    
            dataCard=DataCard_M${mass[$k]}GeV_ZpZHllbb_13TeV.txt
            rootFile=higgsCombineCounting.Asymptotic.mZH${mass[$k]}.root
	    
	    printf "\E[1;32m"
            echo -e "*** Using data card: " $dataCard " to calculate limits ***"
	    printf "\E[0m"

            combine -M Asymptotic $pwd/$dataCarddr/$dataCard
            mv higgsCombineTest.Asymptotic.mH120.root $pwd/$rootFile
	    
	done
	
        ## plot the results from the root files generate from combine tool ##
	
	cd $pwd
	
	printf "\E[1;32m"
	echo -e "*** Plot the results using plotAsymptotic.C ***"
	printf "\E[0m"
	
	root -q -b -l plotAsymptotic.C+\(\"${CHAN[$i]}\"\,\"${BTAG[$j]}\"\)
	rm -f higgsCombineCounting*root

	echo -e ""
	echo -e ""

    done
done

## combine data cards ##

combineCarddr=combineCards
mkdir -p $combineCarddr

eachCarddr=($(ls -d dataCards*))

for ((i=0; i<${#mass[@]}; i++)); do

    cd $pwd

    dataCard=DataCard_M${mass[$i]}GeV_ZpZHllbb_13TeV.txt
    combineCard=combine_DataCard_M${mass[$i]}GeV_ZpZHllbb_13TeV.txt

    printf "\E[1;32m"
    echo -e "*** Combine data cards in " ${eachCarddr[0]} " " ${eachCarddr[1]} " " ${eachCarddr[2]} " " ${eachCarddr[3]} " ***"
    printf "\E[0m"

    combineCards.py ele1btag=$pwd/${eachCarddr[0]}/$dataCard ele2btag=$pwd/${eachCarddr[1]}/$dataCard mu1btag=$pwd/${eachCarddr[2]}/$dataCard mu2btag=$pwd/${eachCarddr[3]}/$dataCard > $combineCard

    printf "\E[1;32m"
    echo -e "*** Output card: " $combineCard " move to " $combineCarddr " ***"
    printf "\E[0m"

    mv $combineCard $combineCarddr

    ## use the combine tool ##

    cd $cmsswdr/HiggsAnalysis/CombinedLimit/src

    rootFile=higgsCombineCounting.Asymptotic.mZH${mass[$i]}.root

    printf "\E[1;32m"
    echo -e "*** Using data card: " $combineCard " to calculate limits ***"
    printf "\E[0m"
    
    combine -M Asymptotic $pwd/$combineCarddr/$combineCard
    mv higgsCombineTest.Asymptotic.mH120.root $pwd/$rootFile

done

## plot the results from the root files generate from combine tool ##

cd $pwd

printf "\E[1;32m"
echo -e "*** Plot the combine results using plotAsymptotic.C ***"
printf "\E[0m"

root -q -b -l plotAsymptotic.C+\(\"ele+mu\"\,\"1+2\"\)
rm -f higgsCombineCounting*root

## all jobs are completed ##

resultsdr=/afs/cern.ch/user/h/htong/www/limitResults

rm -rf $resultsdr
mkdir -p $resultsdr
mv *pdf $resultsdr
rm -f *.d *.so *.pcm 

printf "\E[1;32m"
echo -e "*** All jobs are completed ***"
echo -e ""
printf "\E[0m"

exit
