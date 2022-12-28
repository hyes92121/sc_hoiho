# README for setting up and customizing ```sc_hoiho``` 

## Setup 
### Step 1: Download the following files to the project folder: 
- midar-IPv4: https://publicdata.caida.org/datasets/supplement/2021-conext-hoiho/202103-midar-iff.routers.bz2 
- public-suffix-list.dat: https://publicdata.caida.org/datasets/supplement/2021-conext-hoiho/public_suffix_list.dat
- geocodes.txt: https://publicdata.caida.org/datasets/supplement/2021-conext-hoiho/geocodes.txt
- hoiho_apply.pl: https://publicdata.caida.org/datasets/supplement/2021-conext-hoiho/hoiho-apply.pl 

### Step 2: Setup ```sc_hoiho```
We will need to build ```sc_hoiho``` with either ```--with-pcre``` or ```--with-pcre2``` to configure. When building ```sc_hoiho```, ensure ```pcre``` (or ```pcre2```) is in the path where your compiler looks for header files and libraries. 

For example: ```CFLAGS='-I/usr/local/include' LDFLAGS='-L/usr/local/lib' ./configure \
 --with-sc_hoiho --with-pcre2```
 
## References
Reference paper: [Learning to Extract Geographic Information from Internet Router Hostnames](https://www.caida.org/catalog/papers/2021_learning_extract_geographic_information/learning_extract_geographic_information.pdf)

Data download link: [https://publicdata.caida.org/datasets/supplement/2021-conext-hoiho/](https://publicdata.caida.org/datasets/supplement/2021-conext-hoiho/)
 
