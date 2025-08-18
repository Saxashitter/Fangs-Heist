pk3name=FangsHeist

rm -rf .tmp

read -p "Optimize songs?: " opti
read -p "Is this a release build?: " rel

if [[ "$opti" == "n" || "$opti" == "N" ]]; then
	optimize=1
else
	optimize=0
fi
if [[ "$rel" == "n" || "$rel" == "N" ]]; then
	release=1
	prefix="-test"
else
	release=0
	prefix="-release"
fi
rm -rf "$pk3name$prefix.pk3"

# Make folder.
cp -r src .tmp

# Optimize songs.

function optimizeSongs() {
	local music=".tmp/Music/"

	local ffmpeg=".tmp/ffmpeg/"
	local optivorbis=".tmp/optivorbis/"

	mkdir "$ffmpeg"

	for file in .tmp/Music/*.ogg;
	do
		local i=${file:10}

		ffmpeg -i $music$i -c:a libvorbis -ar 32000 $ffmpeg$i
	done

	rm -r "$music"

	mv "$ffmpeg" "$music"
}

if [[ "$optimize" == 0 ]]; then
	optimizeSongs
fi

cd .tmp
zip -r9 "../$pk3name$prefix.pk3" *
cd ..
rm -r .tmp
echo "Done!"