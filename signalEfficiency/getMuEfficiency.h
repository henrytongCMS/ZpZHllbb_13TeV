#include <vector>
#include <string>
#include <iostream>
#include <TClonesArray.h>
#include <TLorentzVector.h>
#include "../untuplizer.h"
#include "../isPassZmumu.h"

float geMuEfficiency(string inputFile, int cat){

  // read the ntuples (in pcncu)

  TreeReader data(inputFile.data());
  
  int passEvent = 0;

  // begin of event loop

  for( Long64_t ev = data.GetEntriesFast()-1; ev >= 0; --ev ){

    data.GetEntry(ev);

    TClonesArray*  muP4             = (TClonesArray*) data.GetPtrTObject("muP4");
    Int_t          FATnJet           = data.GetInt("FATnJet");    
    Int_t*         FATnSubSDJet      = data.GetPtrInt("FATnSubSDJet");
    Float_t*       FATjetPRmassCorr  = data.GetPtrFloat("FATjetPRmassL2L3Corr");
    TClonesArray*  FATjetP4          = (TClonesArray*) data.GetPtrTObject("FATjetP4");
    vector<bool>&  FATjetPassIDLoose = *((vector<bool>*) data.GetPtr("FATjetPassIDLoose"));
    vector<float>* FATsubjetSDCSV    = data.GetPtrVectorFloat("FATsubjetSDCSV", FATnJet);

    // select good reco level events     
    // select good leptons
      
    vector<int> goodLepID;

    if( !isPassZmumu(data,goodLepID) ) continue;

    TLorentzVector* thisLep = (TLorentzVector*)muP4->At(goodLepID[0]);
    TLorentzVector* thatLep = (TLorentzVector*)muP4->At(goodLepID[1]);

    // select good FATjet

    int goodFATJetID = -1;
    TLorentzVector* thisJet = NULL;

    for( int ij = 0; ij < FATnJet; ++ij ){

      thisJet = (TLorentzVector*)FATjetP4->At(ij);

      if( thisJet->Pt() < 200 ) continue;
      if( fabs(thisJet->Eta()) > 2.4 ) continue;
      if( !FATjetPassIDLoose[ij] ) continue;
      if( thisJet->DeltaR(*thisLep) < 0.8 || thisJet->DeltaR(*thatLep) < 0.8 ) continue;
      if( FATjetPRmassCorr[ij] < 105 || FATjetPRmassCorr[ij] > 135 ) continue;

      int nsubBjet = 0;

      for( int is = 0; is < FATnSubSDJet[ij]; ++is ){

	if( FATsubjetSDCSV[ij][is] > 0.605 ) ++nsubBjet;

      }
 
      // b-tag cut
 
      if( cat == 1 && nsubBjet != 1 ) continue;
      if( cat == 2 && nsubBjet != 2 ) continue;
       
      goodFATJetID = ij;

      break;
 
    } // end of FatnJet loop
 
    if( goodFATJetID < 0 ) continue;

    if( (*thisLep+*thatLep+*thisJet).M() < 750 ) continue;

    // Noise cleaning?

    if( fabs((*thisLep+*thatLep).Eta()-(*thisLep+*thatLep+*thisJet).Eta()) > 5.0 ) continue;

    ++passEvent;

  } // end of event loop
  
  return (float)passEvent/(float)data.GetEntriesFast();

}