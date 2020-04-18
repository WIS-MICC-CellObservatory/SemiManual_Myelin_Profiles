# Segmentation and quantification of mature isolated myelin rings from serialEM of PNS 

## Overview

Semi Manual segmentation of myelin profiles and g-ratio quantification.
 
1) Automaticaly segment Inner profiles:
	Open the image , run "CountMayelinatedAxons.ijm"  macro 
	It will ask you to draw a line along the scalebar, and select the relavant part of the image for analysis and  
	will find candidates of inner part of the mayelinated axons
 	  
2) Manualy draw the Outer profiles, and correct Inner profiles if needed:
   Open the image , drag and drop the FILINMAE_InnerRoiSet.zip file into Fiji 
   Draw the outer parts of the malinated axon and add them to the RoiManager (see details in ManualEditingInstructions_ForGRatio.txt)
   There may be  non-relevant detections, but don't bother to delete them, 
   as the next step will include only matched pairs of inner&outer ROIs
   Save the ROI file when done to Results\FileName_InnerOuterRoiSet.zip
    
3) Match Inner and Outer Profiles and calculate g-ratio
	Open the image, run the "GratioOfManualOuter_MayelinatedAxons.ijm" macro
	it will open the Roi file from step 2, find pairs of inner/outer ROIs and for each pair calculate the g-ratio


Written by: Ofra Golani at MICC Cell Observatory, Weizmann Institute of Science

In collaboration with Anya Vainshtein, Christina Katanov and Elior Peles, Weizmann Institute of Science

Software package: Fiji (ImageJ)

Workflow language: ImageJ macro

Used in : 
N-Wasp regulates oligodendrocyte myelination
Christina Katanov, Nurit Novak, Anya Vainshtein, Jeffery L Dupree, and Elior Peles

 



