# SarConfoCal - Simultaneous Fluorescence and Sarcomere Length Measurements from Laser Scanning Confocal Microscopy (LSCM) Images
Plugins and toolbars for ImageJ 
===============================
Côme PASQUALIN - François GANNIER (gannier at univ-tours dot fr) 
University of Tours (France)

Date : 2016/06/27 first version

Please visit http://pccv.univ-tours.fr/ImageJ/SarConfoCal/ to download and for more information

Tested on ImageJ 1.50i (linux, Mac OS and Windows)

Installation
------------
 - Download SarConfoCal.ijm and copy it into the "ImageJ\macros\toolsets" folder.
 - Start ImageJ or restart it if already opened.
 - In the "More tools" menu (>>) of the toolbar, select "SarConfoCal". A new set of buttons should now be present on the right side of the toolbar, as shown in the top figure below. SarConfoCal is now ready to use.
 
User guide
----------
 - Open in ImageJ a multi-channel image contening multiple lines from line-scanning confocal microscopy (x-scan horizontally, time vertically). For sarcomere length measurements, you need at least one channel with transmission image.
- Verify the vertical (temporal) calibration (button 1). This should correspond to the time of aqcuisition between two lines. Change it if needed.
- Verify the horizontal (spatial) calibration (button 2). This should correspond to the pixel width. Change it if needed.

N.B.: Most images from confocal microscopy can be imported with Bio-Formats, then spatial and temporal calibration should be correctly done.

- Eventually, you can visualize the FFT spectrum (button 3)
- Then, use button 4 to launch analysis. 
