# Makefile for Apple SDK with Open Tool Chain Headers for firmware 2.0

PROJECTNAME = ScreenSplitr

DEV = /Developer/Platforms/iPhoneOS.platform/Developer
SDK = $(DEV)/SDKs/iPhoneOS2.0.sdk
CC = $(DEV)/usr/bin/gcc-4.0
LD = $(CC)
VERSION = iPhoneOS,2.0

LDFLAGS = -arch arm -lobjc 
LDFLAGS += -framework CoreFoundation 
LDFLAGS += -framework Foundation 
LDFLAGS += -framework UIKit 
LDFLAGS += -framework IOKit 
#LDFLAGS += -framework LayerKit 
LDFLAGS += -framework CoreGraphics 
LDFLAGS += -framework GraphicsServices 
LDFLAGS += -framework CoreSurface 
LDFLAGS += -framework CoreAudio 
LDFLAGS += -framework Celestial 
LDFLAGS += -framework AudioToolbox 
LDFLAGS += -framework MediaPlayer 
LDFLAGS += -framework QuartzCore 
LDFLAGS += -L"$(SDK)/usr/lib" 
LDFLAGS += -F"$(SDK)/System/Library/Frameworks" 
LDFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks" 

CFLAGS = -arch arm 
CFLAGS += -I"/Developer/SDKs/iPhoneOS.sdk/Versions/iPhoneOS2.0.sdk/include" 
CFLAGS += -I"$(SDK)/usr/include" 
CFLAGS += -I"$(DEV)/usr/lib/gcc/arm-apple-darwin9/4.0.1/include" 
CFLAGS += -F"/System/Library/Frameworks" 
CFLAGS += -F"$(SDK)/System/Library/Frameworks" 
CFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks" 
CFLAGS += -DASPEN -DDEBUG -DVERSION='"$(VERSION)"' -O3 -funroll-loops 
CFLAGS += -DMAC_OS_X_VERSION_MAX_ALLOWED=1050

BUILDDIR = ./build/2.0
SRCDIR = ./src
RESDIR = ./resources
OBJS = $(patsubst %.m,%.o,$(wildcard $(SRCDIR)/*.m))
OBJS += $(patsubst %.c,%.o,$(wildcard $(SRCDIR)/*.c))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/*.cpp))
RESOURCES = $(wildcard $(RESDIR)/*)
ZIPNAME = $(PROJECTNAME).zip

all:	clean dist

$(PROJECTNAME):	$(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

%.o:	%.m
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

%.o:	%.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

%.o:	%.cpp
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

$(ZIPNAME): $(PROJECTNAME) $(RESOURCES)
	rm -rf $(BUILDDIR)
	mkdir -p $(BUILDDIR)
	cp -r $(PROJECTNAME).app $(BUILDDIR)
	cp $(RESDIR)/* $(BUILDDIR)/$(PROJECTNAME).app
	cp $(PROJECTNAME) $(BUILDDIR)/$(PROJECTNAME).app
	find $(BUILDDIR) -type f -name .DS_Store -print0 | xargs -0 rm
	find $(BUILDDIR) -name .svn -print0 | xargs -0 rm -rf
	zip -r $(ZIPNAME) $(BUILDDIR)

dist:	$(ZIPNAME)
	@md5 $(ZIPNAME)
	@echo "date =" `date +%s`
	@echo "size =" `ls -l $(ZIPNAME) | awk '{print $$5;}'`

clean:
	@rm -f $(SRCDIR)/*.o $(SRCDIR)/*.gch
	@rm -rf $(BUILDDIR)
	@rm -f $(ZIPNAME)
