/* Count Myelinated axons from one opened EM image
 * By: Ofra Golani, March 2017
 * For: Anya Vainshtein, Christina Katanov, Ori Peles Lab
 *
 * Usage Instructions
 * ==================
 * This macro is the first step for semi-manual g-ratio Quantification:
 * 
 * 1) Open the image , run "CountMayelinatedAxons.ijm"  macro 
 * 	  It will ask you to draw a line along the scalebar, and select the relavant part of the image for analysis and  
 * 	  will find candidates of inner part of the mayelinated axons
 * 	  
 * 2) Open the image , drag and drop the FILINMAE_InnerRoiSet.zip file into Fiji 
 *    Draw the outer parts of the malinated axon and add them to the RoiManager (see details below)
 *    There may be  non-relevant detections, Don't bother to delete them, 
 *    as the next step will include only matched pairs of inner&outer ROIs
 *    Save the ROI file when done (see ManualEditingInstructions_ForGRatio.txt)
 *    
 * 3) Open the image, run the "GratioOfManualOuter_MayelinatedAxons.ijm" macro
 *    it will open the Roi file from step 2, find pairs of inner/outer ROIs and for each pair calculate the g-ratio
 * 
 * Workflow
 * =========
 * 
 * 1) Scale the image according to the scalebar and mask out the non-data parts of the image
 * 		This is done with user-interaction: 
 * 		The user is asked to draw the scalebar and give the its correct length 
 * 		The user id asked to select the part of the image that really includes the data 
 * 		Both scaled image and the selected mask are saved to the Results subfolder, 
 * 		When running the macro again (eg with different parameters) the macro read these images (if exist) and avoid repeated user interaction
 * 		
 * 		All the parameters are in um, and the measurements are scaled to correct units based on the scalebar
 * 		
 * 2) Find candidate objects:
 * 		- Smooth with mean filter (3 pixels) 
 *		- Bandpass filter to enhance features between MinMyelinWidth to MaxMayelinWidth 
 * 		- Apply Fix threshold to convert to binary image 
 * 		- Fill holes smaller than minFillArea 
 * 		- Create connected components using Analyze Particles, 
 * 		- Discard small and non-circular objects :  
 *			- Area < minInnerArea   OR  
 *			- Circularity < minCircularity   OR 
 *			- Solidity < minSolidity  OR 
 *			- Round < minRound
 * 3) To help the next step: rename all valid Rois to have "I-" prefix
 * 4) Save RoiSet & InnerOverlay image
 * 5) All the used oarameters are saved into "MacroParameterLog.txt"
 * 
 * Output
 * ======
 * All output files are saved in  a Results subfolder under the original location. 
 * For file named FILE_NAME , the outputs are 
 * 
 */

//-------------------------------------------------------------------------------------//
// Parameters
//-------------------------------------------------------------------------------------//
defaultKnownDist = 2;
defaultKnownUnit = "umunit"

//minMyelinWidth = 0.045; // um
//maxMyelinWidth = 0.135; // um

minMyelinWidth = 0.04; 	// um
maxMyelinWidth = 0.35;  // um

EnhancedMyelinTh = 120; 
minFillArea = 0.002;   // um
minInnerArea = 0.008   // um 
minCircularity = 0.3;  
minRound = 0.2; 		
minSolidity = 0.5; 		
smoothFlag = 0; 	   // enable closing holes due to mito close to the border, BUT it also smooth convex axon
cleanupFlag = 1;

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

//-------------------------------------------------------------------------------------//
// Set Names
//-------------------------------------------------------------------------------------//

origIm=getImageID();
orig_name = getTitle();
orig_name_no_ext = replace(orig_name, ".tif", "");
orig_name_no_ext = replace(orig_name_no_ext, " ", "_");
orig_name_no_ext = replace(orig_name_no_ext, ".", "_");
origFolder = getInfo("image.directory");
resDir = origFolder + File.separator + "Results" + File.separator;
File.makeDirectory(resDir);

//-------------------------------------------------------------------------------------//
// Print & Save Parameters 
//-------------------------------------------------------------------------------------//
print("Macro: CountMyelinatedAxons.ijm, Parameters:"); 
print("minMyelinWidth=", minMyelinWidth, " um"); 
print("maxMyelinWidth=", maxMyelinWidth, " um"); 
print("EnhancedMyelinTh=",EnhancedMyelinTh);
print("minFillArea=", minFillArea, " um");
print("minInnerArea=", minInnerArea, " um");
print("minCircularity=",minCircularity); 
print("minRound=",minRound); 
print("minSolidity=",minSolidity); 
selectWindow("Log");
saveAs("Text", resDir+"MacroParameterLog.txt");

//-------------------------------------------------------------------------------------//
// scale the original image
//-------------------------------------------------------------------------------------//
scaleImage(orig_name, origIm, resDir, defaultKnownDist, defaultKnownUnit);
getPixelSize(unit, pw, ph);
minMyelinWidthPix = minMyelinWidth / pw;
maxMyelinWidthPix = maxMyelinWidth / pw;

//-------------------------------------------------------------------------------------//
// select Region of Interest: Ask the user to select ROI - on the 2D image 
//-------------------------------------------------------------------------------------//
GetUserMask(resDir, orig_name_no_ext);


//-------------------------------------------------------------------------------------//
// Find candidate Myelin and Inner parts 
//-------------------------------------------------------------------------------------//
selectImage(origIm);
run("Duplicate...", "title=MyelinMask");

run("Mean...", "radius=3");

run("Bandpass Filter...", "filter_large="+maxMyelinWidthPix+" filter_small="+minMyelinWidthPix+" suppress=None tolerance=5 autoscale saturate");
//setAutoThreshold("Default");
setThreshold(0, EnhancedMyelinTh);
setOption("BlackBackground", false);
run("Convert to Mask");
run("Invert");
run("Analyze Particles...", "size="+minFillArea+"-Infinity circularity=0-1.00 show=Masks display exclude clear summarize add");
run("Fill Holes");
run("Erode");
//run("Erode");
run("Dilate");

rename("InnerMask");
// Apply the UserMask  to Inner Mask
imageCalculator("AND", "InnerMask","UserMask"); 
//rename("InnerMaskAndUserMask");

run("Set Measurements...", "area mean standard modal min fit shape feret's median display add redirect=None decimal=2");
run("Analyze Particles...", "size="+minInnerArea+"-Infinity circularity="+minCircularity+"-1.00 show=[Count Masks] display exclude clear summarize add");
CountMaskIm = getImageID();

//-------------------------------------------------------------------------------------//
// Filter out some Inner parts 
//-------------------------------------------------------------------------------------//
nRoi = roiManager("Count");
nDeleted = 0;
for (n = nRoi-1; n >= 0; n--)
{	
	roiManager("Select",n);
	solidity = getResult("Solidity", n);
	roundm = getResult("Round", n);
	if ((solidity < minSolidity) || (roundm < minRound))
	{
		roiManager("Delete");
		nDeleted = nDeleted + 1;
		//print(n,solidity,roundm,"Deleted",nDeleted);
	}
	else
	{
		roiName=call("ij.plugin.frame.RoiManager.getName", n);
		roiManager("rename", "I-"+roiName);
		//print(n,solidity,roundm,"Good");
		if (smoothFlag)
		{
			smoothSelection();
			roiManager("Update");
		}
	}
}
nFinalRoi = roiManager("Count");
print("nDetectedObjects=",nRoi,"nValidObjects=",nFinalRoi);

selectWindow(orig_name);
roiManager("Show All without labels");

//-------------------------------------------------------------------------------------//
// Save Results
//-------------------------------------------------------------------------------------//
roiManager("Save", resDir+orig_name_no_ext+"_InnerRoiSet.zip");
selectImage(origIm);
roiManager("Deselect");
roiManager("Show None");
roiManager("Set Color", "yellow");
roiManager("Set Line Width", 2);
roiManager("Show All without labels");
run("Flatten");
saveAs("Tiff", resDir+orig_name_no_ext+"_InnerOverlay.tif");

if (cleanupFlag)
{
	run("Close All");
	if (isOpen("Results"))
	{
		selectWindow("Results");
		run("Close");
	}
	roiManager("reset");
}


// =========================== Helper Functions ======================================================

function smoothSelection() {
	if (selectionType==-1) return;
	run("Convex Hull");
	run("Interpolate", "interval=1 smooth adjust");
}


// =================================================================================
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

// =================================================================================
// look for existing mask in the results folder, 
// if it does not exist, then ask the user to draw a rectangle around the scalebar, and save it for later runs
// Set the name of the mask to be: "UserMask"
// At the end of the function make sure to get back to the initially selected Image
function GetUserMask(resFolder, origName_noExt)
{
	UserMaskName = origName_noExt+"_UserMask.tif";

	Im = getImageID();
	if (File.exists(resFolder+UserMaskName))
	{
		// Read UserMask
		open(resFolder+UserMaskName);
		rename("UserMask");
		selectImage(Im);
	} else 
	{   
		setTool("rectangle");
		waitForUser("Draw a ROI to be analyzed, click OK when you are done");
		run("Create Mask"); //creating a roi mask
		// save the mask
		saveAs("Tiff", resFolder + UserMaskName);
		rename("UserMask");
		// Cleanup
		selectImage(Im);
		run("Select None");
		setTool("hand");		
	}
}

// =================================================================================
