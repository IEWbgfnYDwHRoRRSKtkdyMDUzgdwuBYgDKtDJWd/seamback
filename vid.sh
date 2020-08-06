#!/bin/bash
function vidinfo () {
INPUT="${FILE}"

frames=$(ffprobe -select_streams v -show_streams $INPUT 2>/dev/null | grep nb_frames | sed -e 's/nb_frames=//')
duration=$(ffprobe -loglevel error -show_streams $INPUT | grep duration= | cut -f2 -d= | head -1)
duration2=$(echo $(echo "$(ffprobe -loglevel error -show_streams $INPUT | grep duration= | cut -f2 -d= | head -1 ) / 60" | bc -l) mins)
fps1=$(ffprobe -i $INPUT -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate)
fps2=$(ffmpeg -i $INPUT 2>&1 | sed -n "s/.*, \(.*\) tbr.*/\1/p")
width=$(ffprobe -select_streams v -show_streams $INPUT 2>/dev/null | grep coded_width | sed -e 's/coded_width=//')
height=$(ffprobe -select_streams v -show_streams $INPUT 2>/dev/null | grep coded_height | sed -e 's/coded_height=//')
display_aspect=$(ffprobe -select_streams v -show_streams $INPUT 2>/dev/null | grep display_aspect_ratio | sed -e 's/display_aspect_ratio=//')
bit_rate=$(ffprobe -select_streams v -show_streams $INPUT 2>/dev/null | grep bit_rate | sed -e 's/bit_rate=//')

echo ------------------------------- 
echo Vidinfo: $INPUT 
echo  
echo frames: "$frames"
echo duration: "$duration"
echo duration2: "$duration2"
echo fps1: "$fps1"
echo fps2: "$fps2"
echo width: "$width"
echo height: "$height"
echo display_aspect: "$display_aspect"
echo bit_rate: "$bit_rate"
echo ------------------------------- 
}

#if [ ! -d "$framedir" ]
#  then mkdir $framedir
#fi
FILE=$1
dx=$2
dy=$3
factor=0.8
framedir=frames
mkdir frames
adir=aout
mkdir aout
bdir=bout
mkdir bout

START1=$(date +%s);

		vidinfo
		aSIZE1=$(echo $factor*$((width)) | bc -l )
		aSIZE2=$(echo $factor*$((height)) | bc -l )
		bSIZE1=$width
		bSIZE2=$height
		FPS=$(echo "$frames / $duration" | bc -l)

		echo -e "\nExtracting thumbnails for \"${FILE}\"" 
		ffmpeg \
			-i "${FILE}" \
			-vf fps=fps=$FPS \
			frames/"${FILE%.*}"_%0d.png 2>/dev/null

		piccounta=$(echo $(ls "$framedir"/*.png 2>/dev/null | wc -l ))
		piclist=
		countera=${piccounta}
		echo "------------------------------------------------"
		echo -e aLiquid Resizing $piccounta frames dx = "$dx" dy = "$dy"
		echo "------------------------------------------------"
		
		cd "$framedir"
		ls *.png >../list.txt
		cd ../
		while read line; do

			function pass () {
				python seam_carving.py -resize -im frames/"$line" -out aout/"$line"  -dx "$dx" -dy "$dy" 2>/dev/null
			}
		
			START2=$(date +%s);
			pass;
			END2=$(date +%s);
			elapsed=$(echo $((END2-START2)) | awk '{print int($1/60)":"int($1%60)}')
			elapsedtotal=$(echo $((END2-START1)) | awk '{print int($1/60)":"int($1%60)}')
			timsec=$(echo $((END2-START2)) | awk '{print int($1%60)}')
			predicted=$(echo $((timsec*countera)) | awk '{print int($1/60)":"int($1%60)}')
			((--countera));
			echo \[$countera "/" $piccounta\] Pass = \[$elapsed\] "|" Elapsed = \[$elapsedtotal ">~" $predicted\]
			
		done <list.txt
 
		# piccountb=$(echo $(ls "$adir"/.*.png 2>/dev/null | wc -l ))
		# counterb=${piccountb}
		# echo "------------------------------------------------"
		# echo -e "bLiquid Resizing $piccountb frames to \""${bSIZE1}"x"${bSIZE2}"\"" 
		# echo "------------------------------------------------"

		# for i in $adir/.*.png; do
		# convert "$i" -liquid-rescale "${bSIZE1}"\!x"${bSIZE2}"\! -gravity center -set filename:orig %t $bdir/%[filename:orig].png
		# ((--counterb)); 
		# echo Amount left bout: $counterb of $piccountb; 
		# done
 
		echo -e "acompiling video...";
		ffmpeg \
			-i "$adir"/"${FILE%.*}"_%0d.png \
			-c:v libx264 \
			-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
			-r $FPS \
			-threads 0 \
			liq_a_"${FILE}"
		
		# echo -e "bcompiling video...";
		# ffmpeg \
		# 	-i $bdir/._"${FILE}"_%0d.png \
		# 	-c:v libx264 \
		# 	-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
		# 	-r $FPS \
		# 	-threads 0 \
		# 	liq_b_"${FILE}"
			
		echo -e "mapping orig audio if it was there...";
		ffmpeg \
			-i liq_a_"${FILE}" \
			-i "${FILE}" \
			-c:v copy \
			-map 0:v:0 -map 1:a:0 \
			-threads 0 \
			mapd-liq_a_"${FILE}"
		
		# echo -e "bcompiling video...";
		# ffmpeg \
		# 	-i liq_b_"${FILE}" \
		# 	-i "${FILE}" \
		# 	-c:v copy \
		# 	-map 0:v:0 -map 1:a:0 \
		# 	-threads 0 \
		# 	mapd-liq_b_"${FILE}"

		echo -e "Cleaning up tempfiles...\n"
		#rm -f $framedir/._"${FILE}"_*.png 


