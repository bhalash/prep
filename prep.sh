#!/usr/bin/env zsh

# The MIT License (MIT)
# 
# Copyright (c) 2015 Mark Grealish (mark@bhalash.com)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#
# Source Config File
#

conf=~/.config/prep/config

if [[ ! -f $conf ]]; then
    touch $conf
    # Output stuff here. TODO
fi 

source $conf

#
# Script Variables
#

# Incremented count of images.
count=1
# Pastable hyperlink.
html=''

#
# Functions
#

link_html() {
    # 
    # Add an extra line of link HTML. In Emmet: 
    # a>img[src="image", srcset="image"]
    #

    # srcset image list.
    local srcset=''
    # Link alt and title text.
    local alt_text='CHANGE ME'
    # URL of image, sans filename, size and extension.
    local image_url="${url_prefix}${url_domain}/${src_folder}/${thumb_folder}"
    # Image name without extension.
    local image_name=$(sed -e 's/\..*//' <<< $1)
    # Link src and href.
    local src="${image_url}/${image_name}_${responsive_sizes[2]}.jpg"

    for n in $(seq 2 ${#responsive_sizes}); do
        # I skip the first, largest size because it does not suit my blog.
        size=${responsive_sizes[$n]}
        srcset+="${image_url}/${image_name}_${size}.jpg ${size}w"

        if [[ $n < ${#responsive_sizes} ]]; then
            srcset+=', '
        fi
    done

    link="<a title=\"${alt_text}\" href=\"${src}\"><img src=\"${src}\" "
    link+="srcset=\"${srcset}\" alt=\"${alt_text}\" /></a>"

    echo $link
}

resize_image() {
    # 
    # Create reduced copies of an image.
    #

    for size in $responsive_sizes; do
        if [[ $size != 1024 ]]; then
            local filename="$(sed -e 's/\..*//' <<< $1)_${size}.jpg"
            cp $1 $filename
        else 
            local filename=$1
        fi

        # 1. -quality Reduce quality to 60%
        # 2. -format JPG format.
        # 3. -resize Resize to ${size}, but only if bigger.
        # 4. -interlace Progressively encode (interlace)
        #    See: https://blog.codinghorror.com/progressive-image-rendering/
        # 4. -filter Apply a smoothing Lanzos filter
        # 5. -strip Strip all meta data.
        # 6. -define Set a maximum output filesize of 150kb
        # 7. $filename
        mogrify -quality 60 -format jpg -resize "${size}"x\> -interlace plane \
            -filter Lanczos -strip -define jpeg:extent=150kb $filename &
    done
}

put_clipboard() {
    #
    # Pipe variable ot the clipboard.
    #

    uname=$(uname)

    if [[ $uname == 'Linux' ]]; then
        xclip -sel clip <<< $1
    elif [[ $uname == 'Darwin' ]]; then
        pbcopy <<< $1
    elif [[ $uname =~ '^CYGWIN_' ]]; then
        putclip <<< $1
    fi
}

#
# Main Loop
#

if [[ "$#" < 2 ]]; then
    echo "Error: Please provide an image and a folder!"
    exit 1
fi

if [[ ! -d $1 ]]; then
    # Create the directory.
    mkdir -p $1/$thumb_folder
elif [[ -d $1/$thumb_folder ]]; then
    # If folder eixsts, clean out thumbnails.
    rm $1/$thumb_folder/*.jpg
fi

src_folder="$1"
shift

for n in "$@"; do
	if [[ -e "$1" ]]; then
        # Original image, will not be compressed.
		cp "$1" $src_folder/$count.jpg
        # Compressed thumbnail sizes.
		cp "$1" $src_folder/$thumb_folder/$count.jpg
		let count++
		shift
	fi
done

cd $src_folder/$thumb_folder

if [[ $(ls -1 *.jpg 2> /dev/null | wc -l) == 0 ]]; then
    # Exit if the script did not find files to copy.
    echo "No images selected!"
    rm -r $(pwd)
    exit 1
fi

for img in *.jpg; do
    # Resize the 'master' and thumbnail images.
    resize_image $img
    # Add a line to the final HTML.
    html+=$(link_html $img)
done

# Add HTML to the clipboard.
put_clipboard $html

until [[ $(ps cax | grep mogrify; echo $?) != 0 ]]; do
    # If many images are queued to process the rest of the script can lag 
    # behind mogrify. This checks every half second if mogrify has finished.
    sleep 0.5
done

# Upload images over scp.
scp -r $(sed -e "s,/${thumb_folder}$,," <<< $PWD) \
    "${remote_server}:${remote_path}/${src_folder}" 2>&1 > /dev/null &
