## prep
[prep](https://github.com/bhalash/prep) is a zshell script which I used to gather, crop, compress and upload images to my blog, as well as generate the HTML code and add it to my clipboard. 

### Configuation
[config.sample](/config.sample) contains an example configuation for prep: 

    # Save as ~/.config/prep/config

    # Name of image thumbnail folder.
    thumb_folder="m"

    # SSH username@server (or alias) and remote path.
    remote_server='user@server'
    remote_path='/var/www/magicsparklyponies.com'

    # Image hyperlink prefix and domain name.
    url_prefix='https://'
    url_domain='magicsparklyponies.com'

    # Responsive image sizes.
    responsive_sizes=(
       1024 840 768 640 424
    )

You should save this configuation file to `~/.config/prep/config` and populate it with values for your server.

### Dependencies
* [ImageMagick](http://www.imagemagick.org/script/index.php).
* [scp](http://linux.die.net/man/1/scp).
* [xclip](http://linux.die.net/man/1/xclip) (Linux)/[putclip](http://gnuwin32.sourceforge.net/packages/cygutils.htm) (Cygwin).

### Use
Simple: 

    prep <folder name> <file 1> <file 2> <file 3> ... <file 10>
    
### Output
    
Code along this line will be automagially added to your clipboard, ready to paste into a blog post:

    <a title="CHANGE ME" href="https://magicsparklyponies.com/folder/m/1_840.jpg">
        <img src="https://magicsparklyponies.com/folder/m/1_840.jpg" srcset="https://magicsparklyponies.com/folder/m/1_840.jpg 840w, https://magicsparklyponies.com/folder/m/1_768.jpg 768w, https://magicsparklyponies.com/folder/m/1_640.jpg 640w, https://magicsparklyponies.com/folder/m/1_424.jpg 424w" alt="CHANGE ME" />
    </a>

The file structure is (assuming default names):

    folder
    ├── 1.jpg
    └── m
        ├── 1.jpg
        ├── 1_424.jpg
        ├── 1_640.jpg
        ├── 1_768.jpg
        └── 1_840.jpg

### TODO
Long list:

* Add better check for host OS (Linux, OS X or [Cygwin](https://www.cygwin.com/)).
* Add test for dependencies.
* Spawn configuration file and prompt for content, if it does not exist.
* Add back temp folder to handle uploaded images.
* Handle args forfor server and responsive image size variables. 
* Gentler handling of original images.

### License 
Prep is available under the [MIT License](https://opensource.org/licenses/MIT). Go wild. 

### Support
None whatsoever. I discliam all responsibility for the risk that prep might eat your hard disk or impact your libido. 
