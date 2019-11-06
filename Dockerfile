#The MIT License
#
#  Copyright (c) 2015-2018, CloudBees, Inc. and other Jenkins contributors
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.

FROM ubuntu:16.04
MAINTAINER Pollen Metrology <admin-team@pollen-metrology.com>

# https://docs.docker.com/get-started/part2/#build-the-app
# https://github.com/shufo/jenkins-slave-ubuntu/blob/master/Dockerfile
# https://github.com/jenkinsci/docker-slave
# https://github.com/jenkinsci/docker-jnlp-slave

ARG VERSION=3.28
ARG user=jenkins
ARG group=jenkins
ARG uid=2222

RUN apt-get clean
RUN apt update

# Install JDK latest edition
RUN apt-get update && apt-get install -y --no-install-recommends default-jdk

# Install utilities
RUN apt-get update && apt-get install -y git wget curl python-virtualenv python-pip build-essential python-dev \
	graphviz locales locales-all bind9-host iputils-ping python3-pip
RUN pip3 install conan

RUN apt-get update && apt-get install -y libeigen3-dev libxt-dev libtiff-dev libpng-dev libjpeg-dev libopenblas-dev \
	xvfb libusb-dev libwrap0-dev

# Mandatory packages for MITK build
RUN apt-get update && apt-get install -y libfreetype6-dev libharfbuzz-dev libgtk2.0-dev 

# Conan now needs Python 3 (and is not needed in this flavour)
# RUN python -m pip install --upgrade pip conan

# QT5 development
RUN apt-get update && apt-get install -y qttools5-dev-tools libqt5opengl5-dev libqt5svg5-dev \
libqt5webkit5-dev libqt5xmlpatterns5-dev libqt5xmlpatterns5-private-dev \
qt5-default qtbase5-dev qtbase5-dev-tools qtchooser qtscript5-dev \
qtdeclarative5-dev qttools5-dev qttools5-private-dev libqt5websockets5-dev

# VTK conan package building dependencies
RUN apt-get update && apt-get install -y freeglut3-dev mesa-common-dev mesa-utils-extra \
libgl1-mesa-dev libglapi-mesa libsm-dev libx11-dev libxext-dev \
libxt-dev libglu1-mesa-dev

# Install compilation utilities
RUN apt-get update && apt-get install -y g++-5 cmake lsb-core doxygen lcov

# Install last fresh cppcheck binary
RUN apt-get update && apt-get install -y libpcre3-dev unzip
RUN cd /tmp && mkdir cppcheck && cd cppcheck && wget https://github.com/danmar/cppcheck/archive/1.89.zip ;  \
	unzip -a 1.89.zip && \
	cd cppcheck-1.89 && \
	make -j4 SRCDIR=build FILESDIR=/usr/bin/cfg HAVE_RULES=yes CXXFLAGS="-O2 -DNDEBUG -Wall -Wno-sign-compare -Wno-unused-function" && \
	make install PREFIX=/usr FILESDIR=/usr/share/cppcheck/ && \
	cd /tmp && \
	rm -rf cppcheck

# Install last fresh lcov binary
RUN cd /tmp && mkdir lcov && cd lcov && wget https://sourceforge.net/projects/ltp/files/Coverage%20Analysis/LCOV-1.13/lcov-1.13.tar.gz ;  \
	tar xvfz lcov-1.13.tar.gz && \
	cd lcov-1.13 && \
	make install PREFIX=/usr CFGDIR=/usr/share/lcov/ && \
	cd /tmp && \
	rm -rf lcov

# Add user jenkins to the image
RUN adduser --system --quiet --uid ${uid} --group --disabled-login ${user}

# Install Phabricator-related tools
RUN apt-get update && apt-get install -y php7.0-cli php7.0-curl
RUN mkdir -p /home/phabricator
RUN cd /home/phabricator && git clone https://github.com/phacility/arcanist.git
RUN cd /home/phabricator && git clone https://github.com/phacility/libphutil.git

# Hack for multiplatform support of Phabricator Jenkins plugin
RUN mv /home/phabricator/arcanist/bin/arc.bat /home/phabricator/arcanist/bin/arc.bat.old
RUN ln -s /home/phabricator/arcanist/bin/arc /usr/bin/arc.bat


RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar

# USER jenkins
RUN apt-get update && apt-get install sudo
RUN echo "${user} ALL = NOPASSWD : /usr/bin/apt-get" >> /etc/sudoers.d/jenkins-can-install 

RUN mkdir -p /home/pollen && chown jenkins:jenkins /home/pollen && ln -s /home/pollen /pollen

# Create a folder for script and copy coverage_validator into it
RUN mkdir -p /home/script && chown jenkins:jenkins /home/script
COPY coverage_validator.sh /home/script
 
# If you put this label at the beginning of the Dockerfile, docker seems to use cache and build fails more often
LABEL Description="This is a base image, which provides the Jenkins agent executable (slave.jar)" Vendor="Jenkins project" Version="1.2"

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


COPY jenkins-slave.sh /usr/bin/jenkins-slave.sh
RUN chmod +x /usr/bin/jenkins-slave.sh

ENTRYPOINT ["/usr/bin/jenkins-slave.sh"]
