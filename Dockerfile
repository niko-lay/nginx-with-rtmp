FROM ubuntu:18.04 as build

ARG PRCE_VER="pcre-8.42"
ARG ZLIB_VER="zlib-1.2.11"
ARG OPENSSL_VER="openssl-1.1.1"


RUN apt update \ 
	&& apt-get install -y \
  	   git \
  	   autoconf \
  	   build-essential \
  	   make \
  	   wget \
	   libxslt1-dev \
	   checkinstall

RUN git clone https://github.com/nginx/nginx
RUN git clone https://github.com/arut/nginx-rtmp-module


RUN    wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/Public-Key \
	&& wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/${PRCE_VER}.tar.gz.sig \
	&& wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/${PRCE_VER}.tar.gz \
	&& gpg --import Public-Key \
	&& gpg --verify ${PRCE_VER}.tar.gz.sig \
	&& tar -xvf  ${PRCE_VER}.tar.gz

RUN	   wget http://zlib.net/${ZLIB_VER}.tar.gz \
	&& wget http://zlib.net/${ZLIB_VER}.tar.gz.asc \
#	&& gpg --verify ${ZLIB_VER}.tar.gz.asc \
	&& tar -xvf ${ZLIB_VER}.tar.gz


RUN	wget https://www.openssl.org/source/${OPENSSL_VER}.tar.gz \
	&& wget https://www.openssl.org/source/${OPENSSL_VER}.tar.gz.asc \
#	&& gpg --verify ${OPENSSL_VER}.tar.gz.asc \
	&& tar -xvf  ${OPENSSL_VER}.tar.gz



	
WORKDIR nginx

RUN git checkout branches/stable-1.14

RUN ./auto/configure \
#		--prefix=/nginx \
		--error-log-path=/dev/stderr \
		--http-log-path=/dev/stdout \
		--pid-path=nginx.pid \
		--with-pcre=../${PRCE_VER} \
		--with-zlib=../${ZLIB_VER} \
		--with-openssl=../${OPENSSL_VER} \
		--with-http_stub_status_module \
		--with-http_v2_module \
		--with-http_ssl_module \
		--with-file-aio \
		--with-http_xslt_module \
		--without-http_ssi_module  --without-http_fastcgi_module  --without-http_uwsgi_module  --without-http_scgi_module --without-http_grpc_module --without-http_memcached_module \
		--add-dynamic-module=../nginx-rtmp-module

RUN  make -j $(getconf _NPROCESSORS_ONLN)
RUN  checkinstall -D -y --nodoc --pkgname=nginx-with-rtmp

##################################################################################

FROM ubuntu:18.04

RUN apt update \
	&& apt install -y ca-certificates libxslt1.1 \
        && rm -rf /var/lib/apt/lists/*

#WORKDIR /nginx

COPY --from=build /nginx/nginx-with-rtmp*.deb .
RUN dpkg -i nginx-with-rtmp*.deb

EXPOSE 1935
EXPOSE 8080

ENTRYPOINT ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
