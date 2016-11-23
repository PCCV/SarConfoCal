/*//////////////////////////////////////////////////////////////////////
// SarConfoCal - Simultaneous Fluorescence and Sarcomere Length Measurements 
from Laser Scanning Confocal Microscopy (LSCM) Images V1.0
// Author: Côme PASQUALIN, François GANNIER
//
// Signalisation et Transport Ionique (STIM)
// CNRS ERL 7368, Groupe PCCV - Université de Tours
//
// Report bugs to authors
// come.pasqualin@gmail.com
// gannier@univ-tours.fr
//
//  This file is part of SarConfoCal.
//  Copyright 2015 Côme PASQUALIN, François GANNIER	
//
//  SarConfoCal is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  SarConfoCal is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with SarConfoCal.  If not, see <http://www.gnu.org/licenses/>.
////////////////////////////////////////////////////////////////// */

var pccv = false;

macro "Time Calibration Action Tool - C000L313fL1151L1f5fT8b091Tfb09s" {
	TPIT = call("ij.Prefs.get", "SarConfoCal.TCalibPixSiz",1);
	getPixelSize(unit, pixelW, pixelH);
	Dialog.create("Time Calibration"); {
		Dialog.addMessage("Vertical Pixel size (T) is "+d2s(pixelH,7)+" s");
		Dialog.addNumber("Change Vertical Pixel size (T) to ", TPIT, 6, 8, "s");
		Dialog.addMessage("Copyright@2016 F.GANNIER - C.PASQUALIN");
		Dialog.show();
		TPIT = Dialog.getNumber();
	}
	run("Properties...", "pixel_height="+TPIT+"");
	call("ij.Prefs.set", "SarConfoCal.TCalibPixSiz",TPIT);
}

macro "Horizontal Calibration Action Tool - C000L1b1fL1dfdLfbffT18091T6809uTb809m" {
	TPIX = call("ij.Prefs.get", "SarConfoCal.XCalibPixSiz",0);
	getPixelSize(unit, pixelW, pixelH);
	Dialog.create("Horizontal Calibration"); {
		Dialog.addMessage("Horizontal Pixel size (X) is "+d2s(pixelW,7)+" "+unit);
		if (TPIX != 0)
			Dialog.addNumber("Pixel size was: ", TPIX, 6, 8, ""+fromCharCode(0x00B5)+"m");
		else Dialog.addNumber("Pixel size: ", 0, 4, 6, ""+fromCharCode(0x00B5)+"m");
		items = newArray(" Use above calibration", " New calibration line (line length below)");
		Dialog.addRadioButtonGroup("Choose: ", items, 2, 1, items[0]);
		Dialog.addNumber("Line length ", 100, 4, 8, ""+fromCharCode(0x00B5)+"m");
		Dialog.addMessage("Copyright@2015-2016 F.GANNIER - C.PASQUALIN");
		Dialog.show();
		TPIX = Dialog.getNumber();
		chargerCalib = Dialog.getRadioButton();
		CalTool = Dialog.getNumber();
	}
	if (chargerCalib == items[0]) {
		run("Properties...", "unit="+fromCharCode(0x00B5)+"m pixel_width="+TPIX+"");
	} else {
		run("Line Width...", "line=1"); setTool("line");
		getLine(x1, y1, x2, y2, lineWidth);
		while (x1 == -1) {
			waitForUser( "Calibration","Please draw a line corresponding to "+CalTool+" "+fromCharCode(0x00B5)+"m and then click OK");
			getLine(x1, y1, x2, y2, lineWidth);
		}
		lineLength = sqrt (((y2-y1)*(y2-y1))+((x2-x1)*(x2-x1)));
		TPIX = CalTool / lineLength;
		run("Properties...", "unit="+fromCharCode(0x00B5)+"m pixel_width="+TPIX+"");
	}
	call("ij.Prefs.set", "SarConfoCal.XCalibPixSiz",TPIX);
}

macro "Linescan FFT Spectrum Action Tool - C000L3d3fL484fL525fL696fL7d7fL8e8fL1fffTa707M" {

	var largeur; var hauteur; var unit; var channels; var slices; var frames;

	xCumul = 2;
	TimeOut = 100;
	ScH = screenHeight;
	ScW = screenWidth;

	getPixelSize(unit, pixelW, pixelH);
	if (unit=="pixels") 
		showMessageWithCancel("Calibration","Video doesn't seem to be calibrated, continue ?");
		
	SLmin = parseFloat(call("ij.Prefs.get", "LSA.SLmin","1"));
	SLmax = parseFloat(call("ij.Prefs.get", "LSA.SLmax","2"));	
	SLslice = parseFloat(call("ij.Prefs.get", "LSA.SLslice","1"));
	Dialog.create("Linescan Spectrum FFT"); {
		Dialog.addNumber("Min Sarcomere length ("+fromCharCode(0x00B5)+"m)", SLmin);
		Dialog.addNumber("Max Sarcomere length ("+fromCharCode(0x00B5)+"m)", SLmax);
		Dialog.addNumber("Sarcomere length channel number:", SLslice); //channel sarco		
		Dialog.addHelp("http://pccv.univ-tours.fr/ImageJ/SarConfoCal/help.html");
		Dialog.addMessage("Copyright@2015-2016 F.GANNIER - C.PASQUALIN");

		Dialog.show();
		SLmin = Dialog.getNumber();
		SLmax = Dialog.getNumber();
		SLslice = Dialog.getNumber();		
		call("ij.Prefs.set", "LSA.SLmin",toString(SLmin));
		call("ij.Prefs.set", "LSA.SLmax",toString(SLmax));
		call("ij.Prefs.set", "LSA.SLslice",SLslice);		
	} 
	
	getLocationAndSize(xwin, ywin, dxwin, dywin);
	getDimensions(largeur, hauteur, channels, slices, frames);
	factor=1;
	if (unit=="nm") { factor = 0.001;	unit = fromCharCode(0x00B5)+"m"; }
	if (unit=="cm") { factor = 10000;	unit = fromCharCode(0x00B5)+"m"; }
	if (unit=="mm") { factor = 1000;	unit = fromCharCode(0x00B5)+"m"; }
	pixelW = roundn(pixelW, 7)*factor;
	pixelH = roundn(pixelH, 7);

	img = getTitle();
	imgID = getImageID();
	selectImage(imgID);
	setSlice(SLslice);
	setTool("rectangle");
	makeRectangle(0, 0, largeur, 1); //selection de la ligne à traiter

	puis2 = Puis2_fft(largeur,largeur);
	fftwin = pow(2,puis2);
	xmin = Posdansfft(fftwin,pixelW,SLmin);
	xmax = Posdansfft(fftwin,pixelW,SLmax);
	HRTimeOut = TimeOut*1000;
	zoom = 1;
	
	if (isOpen(imgID)) {
		selectImage(imgID);
		profile = getProfile();
		fftprofile = Array.fourier(profile, "Hann");
		ZoneiFFTprofile = Array.slice(fftprofile,xmax,xmin);
		Array.getStatistics(ZoneiFFTprofile, Zimin, Zimax, Zimean, ZistdDev);
		PositionDuMax = Array.findMaxima(ZoneiFFTprofile, Zimax-Zimean);
		if (PositionDuMax.length > 0) { 
			PDM = PositionDuMax[0];
		}
		zoom = Zimax/100;
	}
	nomW = "FFT Spectrum of "+img;
	if ((xwin+dxwin)<ScW/2)
		call("ij.gui.ImageWindow.setNextLocation", xwin+dxwin, ywin);
	Plot.create(nomW, "Spatial Freq.", "Energy (AU)");
	Plot.show();
	newTime = parseInt(call("HRtime.gettime"));
	lastTime = newTime;
	
	Spectreid = getImageID();
	selectImage(imgID);
	newline=-1; SLtemp = 0; change = 1;
	while (!isKeyDown("space")) {
		temps = parseInt(call("HRtime.gettime"));
		if (HRTimeOut > 0) {
			temps = parseInt(call("HRtime.sleep",d2s(temps,16), d2s((HRTimeOut - (temps - newTime)),16)));
		}

		lastTime = newTime;
		newTime = temps;
		laps = (newTime - lastTime)/1000.0;

		if (!isOpen(imgID)) break;
		if (!isOpen(Spectreid)) break;
 setBatchMode(true);
		selectImage(imgID);
		type = selectionType();
		if (type != 0) break;
		profile = getProfile();
		getSelectionCoordinates(xpoints, ypoints);
		if (newline != ypoints[0])	{
			newline = ypoints[0];
			fftprofile = Array.fourier(profile, "Hann");
			ZoneiFFTprofile = Array.slice(fftprofile,xmax,xmin);
			Array.getStatistics(ZoneiFFTprofile, Zimin, Zimax, Zimean, ZistdDev);
//			PositionDuMax = Array.findMaxima(ZoneiFFTprofile, Zimax-Zimean);
			PositionDuMax = Array.findMaxima(ZoneiFFTprofile, (Zimax-Zimean)/2);
			if (PositionDuMax.length < 1) { showStatus("Error : press SPACE"); continue; }
			PDM = PositionDuMax[0]; 
			SLtemp = calcOptmizedSL(PDM, 100);
			change = 1;
		}
setBatchMode(false);
		if (isKeyDown("shift"))
			if (is("Caps Lock Set")) {
				zoom/=2;
				change = 1;
			} else {
				zoom*=2;
				change = 1;
		}
		if (change != 0) {
			Plot.create(nomW, "Spatial Freq.", "Energy (AU)");
			zz = zoom*200;
			Plot.setLimits(0, fftwin/2-1, 0, zz);
			Plot.setColor("black");
			Plot.add("lines", fftprofile);

			Plot.setColor("red");
			Plot.drawLine(xmax, 0, xmax, zz);
			Plot.drawLine(xmin, 0, xmin, zz);
			
			Plot.update();
			change = 0;
		}
		ecart += laps;
		if (ecart > 100) {
			st = " SL : " + d2s(SLtemp,2) + "um ";
			if (PositionDuMax.length>1)
				st += "("+PositionDuMax.length+" pks) ";
			else st += "("+PositionDuMax.length+" pk) ";
			st += "at "+d2s((ypoints[0]*pixelH*1000),1)+" ms ";			
			st += " SPACE to stop - UP/DOWN to move";
			showStatus(st);
		}
	}
	showStatus("Linescan FFT Spectrum stopped");
}

macro "Linescan Analysis Action Tool - C000F31bfCfffL3388L88e4L3a8cL8ceb" { 
// VARIABLES GLOBALES
var largeur; var hauteur; var unit; var fftwin; var pixelW; var pixelH; var Debug; var Nbits;
var channels; var SLmax; var SLmin; var CaHD; var imgID;
var AnaMPotential;

Debug = 0;

img = getTitle();
imgID = getImageID();
ScH = screenHeight;
ScW = screenWidth;

if (Debug)
	if (!isOpen("DebugW")) {
		run("New... ", "name=DebugW type=text");
		selectWindow("DebugW");
		setLocation(ScW-350,ScH-300);
	}
/*
	CL = newArray(slices); //pas fait !
*/
	getPixelSize(unit, pixelW, pixelH);
	if (unit=="pixels") 
		showMessageWithCancel("Calibration","Video doesn't seem to be calibrated, continue ?");
// Boîte de dialogue analyse calcium, SL ou les deux
	Dialog.create("Analysis"); {
		var AnaSL=false;
		if (call("ij.Prefs.get", "LSA.AnaSL","false")=="true") AnaSL = true;
		var AnaCalcium=false;
		if (call("ij.Prefs.get", "LSA.AnaCalcium","false")=="true") AnaCalcium = true;
		SLslice = parseFloat(call("ij.Prefs.get", "LSA.SLslice","1"));
		Caslice = parseFloat(call("ij.Prefs.get", "LSA.Caslice","2"));
	
//		Dialog.addMessage("Select your analyses : ");
		Dialog.addCheckbox("Sarcomere length analysis", AnaSL);
		Dialog.addCheckbox("Fluorescence (non ratiometric) analysis", AnaCalcium);
		Dialog.addNumber("Sarcomere length channel number:", SLslice); //channel sarco
		Dialog.addNumber("Fluorescence channel number:", Caslice);
		Dialog.addCheckbox("Plot Fluorescence vs. Sarcomere length",false);
		// Dialog.addMessage("--------------------------------------------------------");
		// Dialog.addCheckbox("Display calcium distribution homogeneity curve", 0);
		// Dialog.addMessage("--------------------------------------------------------");
		// Dialog.addCheckbox("Display SL-calcium general table", 1);
		Dialog.addHelp("http://pccv.univ-tours.fr/ImageJ/SarConfoCal/help.html");
		Dialog.addMessage("Copyright@2015-2016 F.GANNIER - C.PASQUALIN");
		Dialog.show();
		AnaSL = Dialog.getCheckbox();
		AnaCalcium = Dialog.getCheckbox();
		SLslice = Dialog.getNumber();
		Caslice = Dialog.getNumber();
		SLvsF = Dialog.getCheckbox();
		// CaHD = Dialog.getCheckbox();
		// generatable = Dialog.getCheckbox();
		LSA = "false"; if (AnaSL) LSA = "true";
		call("ij.Prefs.set", "LSA.AnaSL",LSA);
		LSA = "false"; if (AnaCalcium) LSA = "true";
		call("ij.Prefs.set", "LSA.AnaCalcium",LSA);
		
		call("ij.Prefs.set", "LSA.SLslice",SLslice);
		call("ij.Prefs.set", "LSA.Caslice",Caslice);
	}
	CaHD = 0; //fixé index homogénéité de distri du Ca
	generatable = 1;
	
	selectImage(imgID);
	getLocationAndSize(xwin, ywin, dxwin, dywin);
	getDimensions(largeur, hauteur, channels, slices, frames);
	factor=1;
	if (unit=="nm") { factor = 0.001;	unit = fromCharCode(0x00B5)+"m"; }
	if (unit=="cm") { factor = 10000;	unit = fromCharCode(0x00B5)+"m"; }
	if (unit=="mm") { factor = 1000;	unit = fromCharCode(0x00B5)+"m"; }
	pixelW = roundn(pixelW, 7)*factor;
	pixelH = roundn(pixelH, 7);
	if (Debug) DebugF("dimensions du pixel (largeur, hauteur): "+pixelW+" ; "+pixelH);
	
	time = newArray(hauteur);	
	for (i=0; i<hauteur; i++) time[i] = i*pixelH*1000; //en ms

	if ((xwin+dxwin)<ScW/2)
		call("ij.gui.ImageWindow.setNextLocation", xwin+dxwin, ywin);
	if (AnaSL) {
		ArraySL = linescan(SLslice); //fonction qui fait le calcul de la SL
		getLocationAndSize(xwin, ywin, dxwin, dywin);
		if ((ywin+dywin)<(ScH-50))
			call("ij.gui.ImageWindow.setNextLocation", xwin, ywin+dywin);
	}
	if (AnaCalcium) ArrayFluo = FluoCa(Caslice,CaHD);
	// if (AnaMPotential) ArrayMP = MemPotential(slice1,slice2); // A FAIRE !

	if (generatable && AnaSL && AnaCalcium) {
		// selectImage(imgID);
		getLocationAndSize(xwin, ywin, dxwin, dywin);
		if ((ywin+dywin)<(ScH-50))
			call("ij.gui.ImageWindow.setNextLocation", xwin+dxwin, ywin);
		Array.show("Sarcomere length - Fluo",time,ArraySL,ArrayFluo);
	}
	if (SLvsF) {
		if (AnaCalcium && AnaSL) {
			getLocationAndSize(xwin, ywin, dxwin, dywin);
			if ((ywin+dywin)<(ScH-50))
				call("ij.gui.ImageWindow.setNextLocation", xwin, ywin+dywin);	
			Plot.create("Fluo vs. SL", "SL (um)", "Fluo (AU)", ArraySL, ArrayFluo);
		}
	}
}



function roundn(num, n) {
	return parseFloat(d2s(num,n))
}

function CloseW(nom) {
	if (isOpen(nom)) {
		// if (Debug) DebugF ("Closing "+nom);
		selectWindow(nom);
		run("Close");
		do { wait(10); } while (isOpen(nom));
	} /* else {
		selectImage(nom);
		run("Close");
	} */
}

function Puis2_fft(largeur,hauteur) {
	if (largeur>=hauteur)
		taillefen =  largeur;
	else  taillefen =  hauteur;
	iii = 0;
	while(taillefen>1) { taillefen /= 2; iii++;}
	return iii;
}

function Fenetre_fft(largeur,hauteur) {
	return pow(2, Puis2_fft(largeur,hauteur));
}

function Posdansfft(fftwin,pix,period) {
// fonction qui renvoie la distance en pixel de la period (en micron "unit") par rapport au centre du spectre DISTANCE ARRONDIE AU PIXEL INFERIEUR !!!
// fftwin = dimension d'un coté du spectre en pixel (ex: 512)
// pix = taille du pixel (en "unit" (microns))
// la period doit etre spécifiée en "unit" donc microns
// renvoi: location
	location = floor ( fftwin * pix / period );
	return location;
}

function linescan(channel){
	//attention, l'image doit etre Temps: vertical descendant, x: horizontal
	//A tester quand linescan taille différent d'un puissance de 2 !
	if (Debug) DebugF ("===== New analyse Linescan =====");
	highRes=1; PDM=0;
	selectImage(imgID);
	setSlice(channel);
	correct = 100;
	//boîte de dialogue pour acquisition des paramètres operateur (si pas de chargement du fichier de param)
	Dialog.create("SL analysis parameters"); {
		var SigDeriv=false;
		if (call("ij.Prefs.get", "LSA.SigDeriv","false")=="true") SigDeriv = true;
		SLmin = parseFloat(call("ij.Prefs.get", "LSA.SLmin","1"));
		SLmax = parseFloat(call("ij.Prefs.get", "LSA.SLmax","2"));
		if (pccv)
			nlines = parseFloat(call("ij.Prefs.get", "SarConfoCal.nlines","1"));
		else nlines = 1;
		Afilter = parseFloat(call("ij.Prefs.get", "SarConfoCal.AAfilter","2"));
		
		Dialog.addMessage("Pixel size(x) : "+d2s(pixelW,7)+" "+unit);
		Dialog.addMessage("Pixel size(t) : "+d2s(pixelH,7)+" s");
		Dialog.addNumber("Minimum sarcomere length :", SLmin, 3, 6, unit);
		Dialog.addNumber("Maximum sarcomere length :", SLmax, 3, 6, unit);
		if (pccv) Dialog.addNumber("Number of line (1 = default) :", nlines);
		Dialog.addNumber("Adjacent/Averaging filter ("+fromCharCode(0x00B1)+" n; 0 = none) :", Afilter);
		if (pccv) Dialog.addNumber("Correction factor (0 = none) :", correct);
		Dialog.addCheckbox("Display signal derivative ", SigDeriv);
		// Dialog.addCheckbox("Display sarcomere shortening homogeneity", 0);
		// Dialog.addCheckbox("Display sarcomere length accuracy interval", 0);
		// Dialog.addCheckbox("Display table at end", 0);
		Dialog.addMessage("--------------------------------------------------------");
		Dialog.addMessage("Warning : Time must be vertical/downward direction");
		Dialog.addMessage("--------------------------------------------------------");
		Dialog.addHelp("http://pccv.univ-tours.fr/ImageJ/SarConfoCal/help.html");
		Dialog.addMessage("Copyright@2016 F.GANNIER - C.PASQUALIN");
		Dialog.show();
		SLmin = Dialog.getNumber();
		SLmax = Dialog.getNumber();
		if (pccv) nlines = Dialog.getNumber();
		Afilter = Dialog.getNumber();
		if (pccv) correct = Dialog.getNumber();
		SigDeriv = Dialog.getCheckbox();
		// sarcomo = Dialog.getCheckbox();
		// SLRL = Dialog.getCheckbox();
		// sauvgraph = Dialog.getCheckbox();
		LSA = "false"; if (SigDeriv) LSA = "true";
		call("ij.Prefs.set", "LSA.SigDeriv",LSA);
		
		if (nlines ==0) nlines=1;
		call("ij.Prefs.set", "LSA.SLmin",SLmin);
		call("ij.Prefs.set", "LSA.SLmax",SLmax);
		call("ij.Prefs.set", "SarConfoCal.nlines",nlines);
		call("ij.Prefs.set", "SarConfoCal.AAfilter",Afilter);
	}
	if (Afilter>0)
		print("Filtering at "+ 1/((Afilter*2+1)*pixelH)+" Hz");
		
	if (SLmax-SLmin < 0) {
		showMessage("Parameter error", "SLmax must be higher than SLmin.");
		linescan(channel);
	}
	
	SLRL = 0;
	sarcomo = 0; //pas de mesure d'homogeneité (fixé)
	sauvgraph = 0; //pas d'affichage du tableau à la fin (fixé)

	fftwin = Fenetre_fft(largeur,largeur);

	if (Debug) DebugF("largeur couverte: "+largeur+" pixels");
	if (Debug) DebugF("duree acquisition: "+hauteur+" pixels");
	if (Debug) DebugF("correspond a : "+hauteur * pixelH+" secondes");
	if (Debug) DebugF("fenetre FFT utilisee: "+fftwin+" pixels");

	//determination de la fenetre de recherche dans la FFT
	xmin = Posdansfft(fftwin,pixelW,SLmin);
	xmax = Posdansfft(fftwin,pixelW,SLmax);

	if (Debug) DebugF("fenetre de recherche dans la FFT pour les SL min et max: "+xmin+" ; "+xmax);

	//création de deux arrays pour SL (et cell length) et une pour l'homogeneité de la contraction
	SL = newArray(hauteur);
	if (sarcomo) SH = newArray(hauteur);
	
	//creation array pour la derivée du signal
	if (SigDeriv) {
		SigDerivArray = newArray(hauteur-1);
	}
	//deux arrays pour les bornes hautes et basses de l'encadrement de la longueur de sarco
	if (SLRL) {
		bMaxSL = newArray(hauteur);
		bMinSL = newArray(hauteur);
	}
	if (Debug) DebugF("Creation des arrays terminee");

	// ANALYSE DES LIGNES
	xCumul = 2; PDM=0;
	for (i=0; i<hauteur; i++) {
		//selection de la ligne
		makeRectangle(0, i, largeur, nlines); //selection de la ligne à traiter
		profile = getProfile();	//récup du profile //EVENTUELLEMENT SMOOTHER LE PROFILE si besoin
		fftprofile = Array.fourier(profile, "Hann"); //ne renvoie que la moitié de la fft (partie droite)
		if (Debug) DebugF("calcul de la FFT termine");
		ZoneiFFTprofile = Array.slice(fftprofile,xmax,xmin); // récup de la zone de l'array contenant le pic
		if (Debug) DebugF("Recuperation de la zone d'interet dans la FFT terminee");
		Array.getStatistics(ZoneiFFTprofile, Zimin, Zimax, Zimean, ZistdDev);
		PositionDuMax = Array.findMaxima(ZoneiFFTprofile, (Zimax-Zimean)/2);
		if (PositionDuMax.length < 1) { beep(); IJ.log("error"); showStatus("Error : press SPACE"); continue; }
		if (PDM!=0 && PositionDuMax.length > 1)
			if (abs(PDM - PositionDuMax[1]) < abs(PDM - PositionDuMax[0]))
				PDM = PositionDuMax[1];
			else PDM = PositionDuMax[0];
		else 
			PDM = PositionDuMax[0];
		if (Debug) DebugF("Zimax : "+Zimax+" Zimean : "+Zimean);
		if (Debug) DebugF("Position du max trouve pour pixel numero : "+PDM);
		ValeurDuMax = ZoneiFFTprofile[PDM];
		if (Debug) DebugF("Amplitude du max : "+ValeurDuMax);
		
		// xCumul = round(4/PositionDuMax.length);
		if (PositionDuMax.length>1)	xCumul = 1;	else xCumul = 2;
		SL[i] = calcOptmizedSL(PDM,correct);

		//remplissage des Array
		// 		if (i>0 && SigDeriv) SigDerivArray[i-1] = (calcOptmizedSL(PDM,correct)-SL[i-1])/(1/pixelH);
		if (sarcomo) SH[i] = ValeurDuMax;
		if (Debug) DebugF("Correspond a une frequence de "+SL[i]+"microns");

		if (SLRL){
			bMaxSL[i]= calcOptmizedSL(PDM+1,correct);
			bMinSL[i]= calcOptmizedSL(PDM-1,correct);
			if (Debug) DebugF("Encadrement valeur reelle: "+bMinSL[i]+" ; "+bMaxSL[i]+" "+unit);
		}
		showProgress(i/hauteur);
	}
	// FIN analyse des lignes
	
	if (Afilter>0) {
		SL = AdjFilter(SL, Afilter);
	}
	//tracage du graphe avec encadrement de l'incertitude pour la longueur de sarco
	Plot.create("Sarcomere length of "+img, "time (ms)", "Sarcomere length ("+unit+")", time, SL);
	if (SLRL) { 
		Plot.add("connected", time, bMaxSL);
		Plot.add("connected", time, bMinSL); 
	}
	Plot.setLineWidth(2);
	Plot.setColor("red");
	Plot.show();
	graphID = getImageID();
	
	//graphe derivée du signal
	if (SigDeriv) {
		for (i=1; i<hauteur; i++) {
			SigDerivArray[i-1] = (SL[i]-SL[i-1])/(1/pixelH);	
		}
		getLocationAndSize(xwin, ywin, dxwin, dywin);
		if ((ywin+dywin)<(ScH-50))
			call("ij.gui.ImageWindow.setNextLocation", xwin, ywin+dywin);

		Plot.create("Derivative", "time (ms)", "Derivative ()", time, SigDerivArray);
		Plot.setLineWidth(2);
		Plot.setColor("blue");
		Plot.show();
	}
	
	//graphe de l'homogeneité de la contraction
	if (sarcomo) {
		getLocationAndSize(xwin, ywin, dxwin, dywin);
		if ((ywin+dywin)<(ScH-50))
			call("ij.gui.ImageWindow.setNextLocation", xwin, ywin+dywin);
		
		Plot.create("Sarcomere shortening homogeneity", "time (ms)", "Sarcomere homogeneity (AU)", time, SH);
		Plot.setLineWidth(2);
		Plot.setColor("blue");
		Plot.show();
	}

	//table générale contenant tout
	if (sauvgraph) {
		 run("New... ", "name=[Sarcomeres] type=Table");
		 if (sarcomo) {
			print("[Sarcomeres]","\\Headings:Time(ms)\tsarcomere length "+unit+"\tsarcomere homogeneity (AU)");
			for (i=0;i<hauteur;i++) { print("[Sarcomeres]",time[i]+"\t"+SL[i]+"\t"+SH[i]); }
		 }
		if (!sarcomo) {
			print("[Sarcomeres]","\\Headings:Time(ms)\tsarcomere length "+unit);
			for (i=0;i<hauteur;i++) { print("[Sarcomeres]",time[i]+"\t"+SL[i]); }
		 }
	}
	selectImage(graphID);
	return SL;
}

function AdjFilter(array, n) {
	NMax = lengthOf(SL);
	SLfilter = newArray(NMax);
	n=0;
	for(i=0; i<Afilter; i++)
		SLfilter[i] = SL[i];
	n += Afilter;
	while(n<NMax-Afilter) {
		sum = 0; 
		for (i=-Afilter;i<=Afilter;i++)
			sum += SL[n+i];
		SLfilter[n] = (sum/(Afilter*2+1));
		n++;
	}
	for(i=NMax-Afilter; i<NMax; i++)
		SLfilter[i] = SL[i];			
	return SLfilter;
}

function DebugF(txt) {
	print("[DebugW]", txt);
}

function FluoCa(channel,CaHD) {
	selectImage(imgID);
	setSlice(channel);
	wait(200);

	//création de l'array calcium concentration
	Amplitude = newArray(hauteur);
	Distribution = newArray(hauteur);

	for (i=0; i<hauteur; i++) {
		//selection de la ligne
		makeRectangle(0, i, largeur, 1);
		getRawStatistics(CanPixels, Camean, Camin, Camax, Castd, Cahistogram);
		Amplitude[i] = CanPixels*Camean;
		Distribution[i] = 1/Castd;
	}

	//tracage du graphe
	Plot.create("Calcium measurement of "+img, "time (ms)", "[Ca] (AU)", time, Amplitude);
	Plot.setLineWidth(2);
	Plot.setColor("green");
	Plot.show();

	if (CaHD) {
		Array.show("Fluorescence",time,Amplitude,Distribution);
		// Plot.create("Calcium homogeneity in cytoplasm", "time (ms)", "Homogeneity of calcium distribution (AU)", Catime, Distribution);
		// Plot.setLineWidth(2);
		// Plot.setColor("blue");
		// Plot.show();
	}
	return Amplitude;
}

function MemPotential(slice1,slice2) {

// A faire!

}

function calcOptmizedSL(PDM, correction) {
	XMax = xmax+PDM;
//	print(lengthOf(ZoneiFFTprofile));
	if (PDM >= xCumul && PDM < lengthOf(ZoneiFFTprofile)-xCumul )
	{
		cumul1 = 0; cumul2 = 0;
		for(ii=-xCumul;ii<=xCumul;ii++)
		{
			cumul1 += (ZoneiFFTprofile[PDM+ii]);
			cumul2 += (ZoneiFFTprofile[PDM+ii]/(XMax+ii));
		}
		rapport = cumul2 / cumul1;
		if (correction!=0) {
			ecart = XMax-(1/rapport);
			rapport += rapport * ecart/correction;
		}
		return pixelW*fftwin*(rapport);
	} else 
		return pixelW*fftwin/XMax;
}