/* GRatioOfManualOuter_MayelinatedAxons.ijm
 *  
 * By: Ofra Golani, March 2017
 * For: Anya Vainshtein, Christina Katanov, Ori Peles Lab

 * Usage Instructions
 * ==================
 * This macro is the Third step for semi-manual g-ratio Quantification:
 * For the opened image file, assuming:
 * 1) Inner Mayelinated areas were automatically found using "CountmayelinatedAxons.ijm",
 * 	  and hence related Roi (FileName"_InnerOuterRoiSet.zip") file and scaled file are saved under the Results subfolder
 * 2) Outer Rois were manually added to the RoiManager and saved in Results\FileName"_InnerOuterRoiSet.zip"
 *    see:  ManualEditingInstructions_ForGRatio.txt
 * 
 * Workflow
 * =========
 * - Look under Results subfolder and open FileName_InnerOuterRoiSet.zip 
 * - Go over Rois and count the inner / outer ones: inner Rois start with I-
 *   for each Inner Roi - find the index of the Roi in the Count Mask table
 *   For each outer Roi 
 * 	 - find the matching Inner Roi 
 *   - measure Inner area, outer area area ratio, calculate effective radius + radius ratio
 *
 *  Output
 * ========= 
 *  1) Table of results with the following values for each axon
 *  	Label of Inner & Outer Rois, 
 *  	Area of Inner and Outer Roi
 *  	effective diameter of Inner and Outer Roi
 *  	G-Ratio based on Area and on effective diameter (inner/outer)
 *  2) Roi file with final Inner/Outer Rois - FileName"_FinalInnerOuterRoiSet.zip"
 *  3) Overlay of the Final Rois - FinalName"_FinalInnerOuterOverlay.tif"
 *  	Inner Roi is colored in cyan by default (controlled by InnerRoiColor)
 *  	Outer Roi is colored in red  by default (controlled by OuterRoiColor)
 */


//-------------------------------------------------------------------------------------//
// Parameters
//-------------------------------------------------------------------------------------//
defaultKnownDist = 2;
defaultKnownUnit = "umunit"
InnerRoiColor= "cyan";
OuterRoiColor= "red";
cleanup_flag = 1;

//-------------------------------------------------------------------------------------//
// Initialization
//-------------------------------------------------------------------------------------//
if (isOpen("Results"))
{
	selectWindow("Results");
	run("Close");
}
roiManager("reset");
if (isOpen("Summary"))
{
	selectWindow("Summary");
	run("Close");  // To close non-image window
}
if (isOpen("Log"))
{
	selectWindow("Log");
	run("Close");  // To close non-image window
}
setTool("hand"); // To make sure the user doesn't create another ROI

//-------------------------------------------------------------------------------------//
// Open related files
//-------------------------------------------------------------------------------------//

origIm=getImageID();
orig_name = getTitle();
orig_name_no_ext = replace(orig_name, ".tif", "");
orig_name_no_ext = replace(orig_name_no_ext, " ", "_");
orig_name_no_ext = replace(orig_name_no_ext, ".", "_");
origFolder = getInfo("image.directory");
resDir = origFolder + File.separator + "Results" + File.separator;

// scale the original image
scaleImage(orig_name, origIm, resDir, defaultKnownDist, defaultKnownUnit);

roiManager("Open", resDir+orig_name_no_ext+"_InnerOuterRoiSet.zip");

//-------------------------------------------------------------------------------------//
// Create label mask using updated inner ROIs only , reload all ROis afterward
//-------------------------------------------------------------------------------------//
nRoi = roiManager("Count");
for (n = nRoi-1; n >= 0; n--)
{	
	roiManager("Select",n);
	roiName=call("ij.plugin.frame.RoiManager.getName", n);
	if (startsWith(roiName, "O-"))
	{
		roiManager("Delete");
	}
}
createLabelMaskFromRoiManager(origIm);
rename("InnerRoiCountMask");
labelMaskIm=getImageID();
roiManager("reset");
roiManager("Open", resDir+orig_name_no_ext+"_InnerOuterRoiSet.zip");
roiManager("Measure");

//-------------------------------------------------------------------------------------//
// Find Matched ROIs of Myelin (Outer ROI) and Axon (Inner ROI)
//-------------------------------------------------------------------------------------//
selectImage(labelMaskIm);
roiManager("Deselect");
roiManager("Show None");
getStatistics(areaCM, meanCM, minCM, maxCM);
nRoi = roiManager("Count");
roiTypeA = newArray(nRoi); // 0=inner, 1=outer
roiNameA = newArray(nRoi); // name of each Roi
roiNewNameA = newArray(nRoi); // new name of each Roi - with prefix of Rnnnn_ where nnnn stands for the pair number
roiActiveA = newArray(nRoi); // is Roi Used either inner/outer
countMaskValA = newArray(nRoi); // countMask value of inner idx
roiAreaA = newArray(nRoi); // Roi Area
outerRoiIdx = newArray(nRoi); // Indexes of all outer Rois only
innerRoiIdx = newArray(nRoi); // Indexes of all inner Rois only
nInnerRoi = 0;
nOuterRoi = 0;
for (n = 0; n < nRoi; n++)
{	
	roiManager("Select",n);
	roiName=call("ij.plugin.frame.RoiManager.getName", n);
	roiNameA[n] = roiName;
	if (startsWith(roiName, "I-"))
	{
		roiTypeA[n] = 0; // Inner
		innerRoiIdx[nInnerRoi] = n;
		nInnerRoi++;
	} else // Outer Roi
	{
		roiTypeA[n] = 1; // Outer
		outerRoiIdx[nOuterRoi] = n;
		nOuterRoi++;
	}
	// find most frequent non-zero value of the countMask within the given outer Roi
	nBins = maxCM + 10;
	getHistogram(values, counts, nBins, 0, nBins);
	maxCount = 0;
	maxVal = -1; // to enable checking for validity
	for (j = 1; j < nBins; j++)
	{
		if (counts[j] > maxCount)
		{
			maxCount = counts[j];
			maxVal = values[j];
		}
	}
	countMaskValA[n] = maxVal; //  the +1 is needed as we started the hist from 1
	roiAreaA[n] = getResult("Area", n);
}


//-------------------------------------------------------------------------------------//
// Print out GRatio for all outer Rois and save the table
//-------------------------------------------------------------------------------------//
saveAs("Results", resDir+orig_name_no_ext+"_AllRoiResults.csv");
IJ.renameResults("Results",orig_name_no_ext+"_AllRoiResults.csv"); // rename results table for saving it from being overwritten by other "Results"
nPairs = 0;
for (n = 0; n < nOuterRoi; n++)
{
	outerIdx = outerRoiIdx[n];
	outCountMaskVal = countMaskValA[outerIdx];
	found = 0;
	if (outCountMaskVal >= 0)
	{
		m = 0;
		innerIdx = 0;
		do {
			id = innerRoiIdx[m];
			inCountMaskVal = countMaskValA[id];
			if (inCountMaskVal == outCountMaskVal)
			{
				innerIdx = id;
				found = 1;
			}
			m++;
		} while ( (m < nInnerRoi) && (found==0))
	}
	if (found==1)
	{
		nPairs++;
		prefix = "R"+pad(nPairs,4,0)+"-";
		roiNewNameA[outerIdx] = prefix + roiNameA[outerIdx];
		roiNewNameA[innerIdx] = prefix + roiNameA[innerIdx];
		roiActiveA[outerIdx] = 1;
		roiActiveA[innerIdx] = 1;
		outerAreaRoiGR = roiAreaA[innerIdx] / roiAreaA[outerIdx];
		
		effeciveOuterDiameter = 2 * sqrt(roiAreaA[outerIdx] / PI);
		effeciveInnerDiameter = 2 *sqrt(roiAreaA[innerIdx] / PI);
		outerDiameterRoiGR = effeciveInnerDiameter / effeciveOuterDiameter;
		
		print(outerIdx, innerIdx, prefix,", NewName:Outer=",roiNewNameA[outerIdx],", NewName:Inner=", roiNewNameA[innerIdx]);
		outName=roiNewNameA[outerIdx];
		inName=roiNewNameA[innerIdx];
		setResult("OuterLabel", nResults, outName); 
		setResult("InnerLabel", nResults-1, inName); 
		setResult("outerCountMaskValue", nResults-1, countMaskValA[outerIdx]); 
		setResult("innerCountMaskValue", nResults-1, countMaskValA[innerIdx]); 
		setResult("InnerArea", nResults-1, roiAreaA[innerIdx]); 
		setResult("OuterArea", nResults-1, roiAreaA[outerIdx]); 
		setResult("AreaGRatio", nResults-1, outerAreaRoiGR); 
		setResult("eInnerDiameter", nResults-1, effeciveInnerDiameter); 
		setResult("eOuterDiameter", nResults-1, effeciveOuterDiameter); 
		setResult("DiameterGRatio", nResults-1, outerDiameterRoiGR); 
	}
	else
	{
		roiActiveA[outerIdx] = 0;
	}
}
saveAs("Results", resDir+orig_name_no_ext+"_FinalResults.csv");

//-------------------------------------------------------------------------------------//
// Delete all non-relevant Rois, and save the Rois of inner/Outer only 
//-------------------------------------------------------------------------------------//
for (n = nRoi-1; n >= 0; n--)
{	
	roiManager("Select",n);
	if (roiActiveA[n] == 0)
	{
		roiManager("Delete");
	}
	else
	{
		if (startsWith(roiNameA[n], "I-"))
		{
			roiManager("Set Color", InnerRoiColor);
			roiManager("Set Line Width", 2);
		}
		else // Outer Roi
		{
			roiManager("Set Color", OuterRoiColor);
			roiManager("Set Line Width", 2);
		}
		roiManager("rename", roiNewNameA[n]);
	}
}
// sort the Rois which have new names now, to put inner and outer Rois together
roiManager("sort");
roiManager("Save", resDir+orig_name_no_ext+"_FinalInnerOuterRoiSet.zip");
selectImage(origIm);
roiManager("Deselect");
roiManager("Show None");
roiManager("Show All without labels");
run("Flatten");
saveAs("Tiff", resDir+orig_name_no_ext+"_FinalInnerOuterOverlay.tif");
flatIm = getImageID();

//-------------------------------------------------------------------------------------//
// Close newly opened images and tables 
//-------------------------------------------------------------------------------------//
if (cleanup_flag == 1)
{
	if (isOpen(orig_name_no_ext+"_AllRoiResults.csv"))
	{
		selectWindow(orig_name_no_ext+"_AllRoiResults.csv");
		run("Close");  // To close non-image window
	}
	if (isOpen("Summary"))
	{
		selectWindow("Summary");
		run("Close");  // To close non-image window
	}
	if (isOpen("Results"))
	{
		//print("Results table will be closed");
		selectWindow("Results");
		run("Close");
	}
	selectImage(labelMaskIm);
	close();
	selectImage(flatIm);
	close();
	roiManager("reset");
}


// =========================== Helper Functions ======================================================
// scaleImage : read a scale image if exist, otherwise ask the user to draw a line to scale the image
function scaleImage(origName, origIm, resDir, defaultKnownDist, defaultKnownUnit)
{
	origName_noExt = replace(origName, ".tif", "");
	scaledName = origName_noExt+"_scaled.tif";

	if (File.exists(resDir+scaledName))
	{
		// Read scaled image
		open(resDir+scaledName);
		scaledOrigIm=getImageID();
		// get the scale
		getVoxelSize(pixelWidth, pixelHeight, pixelDepth, pixelUnit);
		selectImage(origIm);
		setVoxelSize(pixelWidth, pixelHeight, pixelDepth, pixelUnit);
		selectImage(scaledOrigIm);
		close();
	} else 
	{   
		// Scale the image
		selectImage(origIm);
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
		setTool("line");			
		waitForUser("Measure Scalebar Done ?");
		getLine(x1, y1, x2, y2, lineWidth);
		getPixelSize(unit, pw, ph);
		x1*=pw; y1*=ph; x2*=pw; y2*=ph;
		dx = x2-x1; dy = y2-y1;
		length = sqrt(dx*dx+dy*dy);
		print("dx:", dx, ", Length:", length, unit);
		// get the known dist
		UserKnownDist = getNumber("Known Distance (um)?", defaultKnownDist);
		run("Set Scale...", "distance="+dx+" known="+UserKnownDist+" pixel=1 unit="+defaultKnownUnit);
		run("Select None");
		setTool("hand");		

		// Save scaled image
		run("Duplicate...", "title="+scaledName);
		saveAs("Tiff", resDir + scaledName);
		close();
	}
} // end of scaleImage 

// createLabelMaskFromRoiManager - Create Labeled Image based on ROI Manager, apply scaling of the original image
function createLabelMaskFromRoiManager(origIm)
{
	selectImage(origIm);
	getVoxelSize(width, height, depth, unit);
	newImage("Labeling", "16-bit black", getWidth(), getHeight(), 1);
	
	for (index = 0; index < roiManager("count"); index++) {
		roiManager("select", index);
		setColor(index+1);
		fill();
	}

	// apply scaling of original image
	setVoxelSize(width, height, depth, unit);
	
	resetMinAndMax();
	run("glasbey");
}

// Add leading zeros to number
function pad(a, left, right) 
{ 
	while (lengthOf(""+a)<left) a="0"+a; 
	if (right > 0)
	{
		separator="."; 
		while (lengthOf(""+separator)<=right) separator=separator+"0"; 
		return ""+a+separator; 
	}
	else 
		return ""+a;
} 
