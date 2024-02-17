#! /bin/bash

base_path="/media/pfaffenrot/My Passport/pain_layers/main_project/rawdata/"

for prefix in {7484..7485}; do
	dir="$base_path$prefix"
	if [ -d "$dir" ]; then
		tar cfv - "$dir" | pigz  > "$dir.tar.gz"
	fi
done

