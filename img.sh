#!/bin/bash

function imginfo () {
	INPUT="${FILE}"
	width=$(ffprobe -select_streams v -show_streams $INPUT 2>/dev/null | grep coded_width | sed -e 's/coded_width=//')
	height=$(ffprobe -select_streams v -show_streams $INPUT 2>/dev/null | grep coded_height | sed -e 's/coded_height=//')

	echo ------------------------------- 
	echo imginfo: $INPUT 
	echo  
	echo width: "$width"
	echo height: "$height"
	echo ------------------------------- 
}

FILE=$1
#framedir=frames
#mkdir frames
newdir=newcarve
mkdir $newdir
imgmagickdir=imgmagick
mkdir $imgmagickdir

START1=$(date +%s);

		imginfo
		
		x0=$(echo "scale=0; $width/1" | bc)
		x25=$(echo "scale=0; $width/4" | bc)
		x50=$(echo "scale=0; $width/2" | bc)
		x75=$(echo "scale=0; $x25*3" | bc)
		x150=$(echo "scale=0; $x50*3" | bc)
		y0=$(echo "scale=0; $height/1" | bc)
		y25=$(echo "scale=0; $height/4" | bc)
		y50=$(echo "scale=0; $height/2" | bc)
		y75=$(echo "scale=0; $y25*3" | bc)
		y150=$(echo "scale=0; $y50*3" | bc)
		
		function newcarve () {
			echo Scaling with forward seam algo \["$dx" "x" "$dy"\]
			python seam_carving.py -resize -im "$FILE" -out "$newdir"/$dxl-$dyl-"$FILE".jpg -dx $dx -dy $dy 2>/dev/null
		}
		function imagemagickcarve () {
			echo Scaling with imgmagick seam algo \["$dx" "x" "$dy"\]
			convert "$FILE" -liquid-rescale $dx\!"x"$dy\! -gravity center "$imgmagickdir"/$dx-$dy-"$FILE".jpg
		}
		
		dx="-$x50"
		dy="0"
		dxl="$x50"
		dyl="$y0"
		newcarve
		dx="$x50"
		dy="$y0"
		imagemagickcarve
		
		dx="-$x50"
		dy="-$y50"
		dxl="$x50"
		dyl="$y50"
		newcarve
		dx="$x50"
		dy="$y50"
		imagemagickcarve
		
		dx="0"
		dy="-$y50"
		dxl="$x0"
		dyl="$y50"
		newcarve
		dx="$x0"
		dy="$y50"
		imagemagickcarve

		dx="0"
		dy="$y50"
		dxl="$x0"
		dyl="$y150"
		newcarve
		dx="$x0"
		dy="$y150"
		imagemagickcarve

		dx="$x50"
		dy="0"
		dxl="$x150"
		dyl="$y0"
		newcarve
		dx="$x150"
		dy="$y0"
		imagemagickcarve
		
		dx="$x50"
		dy="$y50"
		dxl="$x150"
		dyl="$y150"
		newcarve
		dx="$x150"
		dy="$y150"
		imagemagickcarve


montage -label '%f' "$imgmagickdir"/*.jpg -background none -tile 3 -frame 1 -geometry 200x200 imagickmon.jpg
montage -label '%f' "$newdir"/*.jpg -background none -tile 3 -frame 1 -geometry 200x200  newcarvemon.jpg
