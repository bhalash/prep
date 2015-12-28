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
    local image_url="${url_prefix}${url_domain}/${image_dir}/${thumbnail_folder}"
    # Image name without extension.
    local image_name=${1%.*}
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

    local filename=''

    for size in $responsive_sizes; do
        if [[ $size != 1024 ]]; then
            filename="${1%.*}_${size}.jpg"
            cp $1 $filename
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
            -filter Lanczos -strip -define jpeg:extent=150kb ${filename:=$1} &
    done
}

has_executable() {
    #
    # Check if program exists on the system.
    #

    # Remove everything after the first column.
    which ${1// *//} 2>&1 > /dev/null
    echo $?
}

put_clipboard() {
    #
    # Pipe variable to the clipboard.
    #

    local -a clipboards
    clipboards=('xclip -sel clip' 'pbcopy' 'putclip')

    local clipboard=''

    for prog in $clipboards; do
        if [[ $(has_executable $prog) == 0 ]]; then
            clipboard=$prog
            break
        fi
    done

    if [[ -n $clipboard ]]; then
        eval "${clipboard} <<< '${1}'"
    else
        # Echo out the string if an appropriate clipboard program does not
        # exist.
        echo $1
    fi
}

#
# Script Variables
#

# Incremented count of images.
count=1
# Pastable hyperlink.
html=''
# Config file.
conf=~/.config/prep/config
# Mandatory dependencies.
dependencies=('scp' 'mogrify')

#
# Source Config File
#

if [[ ! -f $conf ]]; then
    echo "Error: Configuration file not found at ${conf}"
    exit 1
fi

source $conf

#
# Check Images and Executables Exist
#

if [[ "$#" < 2 ]]; then
    echo 'Error: Please provide an image and a folder!'
    exit 2
fi

for dependency in $dependencies; do
    if [[ $(has_executable $dependency) != 0 ]]; then
        echo "Error: ${dependency} executable not found in \$PATH"
        exit 3
    fi
done

#
# Setup Temp Directory
#

image_dir=$1
shift

if [[ $(has_executable 'mktemp') != 0 ]]; then
    temp="${TMPDIR}prep.$(date +%s)"
    mkdir $temp
else
    temp=$(mktemp -d)
fi

#
# Setup Thumbnail Directory
#

mkdir "${temp}/${thumbnail_folder}"

#
# Copy Images to Folders
#

for image in "$@"; do
    if [[ -e "${image}" ]]; then
        # Replace filename with count, but preserve extension.
        cp "${image}" "${temp}/${image//${image%.*}/${count}}"
        cp "${image}" "${temp}/${thumbnail_folder}/${count}.jpg"
        let count++
    fi
done

cd "${temp}/${thumbnail_folder}"

#
# Main Loop
#

for img in *.jpg; do
    # Resize the 'master' and thumbnail images.
    resize_image $img
    # Add a line to the final HTML.
    html+=$(link_html $img)
done

if [[ -n $html ]]; then
    cd $temp

    # Add HTML to the clipboard.
    put_clipboard $html

    # If many images are queued to process the rest of the script can lag
    # behind mogrify.
    wait

    # Upload images over scp.
    scp -r . "${remote_server}:${remote_path}/${image_dir}" 2>&1 > /dev/null &
else
    echo 'Error: No valid images were processed by the script.'
    exit 4
fi
