# Makefile for Apple SDK with Open Tool Chain Headers for firmware 2.0

PROJECTNAME = ScreenSplitr

DEV = /Developer/Platforms/iPhoneOS.platform/Developer
SDK = $(DEV)/SDKs/iPhoneOS2.0.sdk
CC  = $(DEV)/usr/bin/gcc-4.0
LD  = $(DEV)/usr/bin/g++-4.0
VERSION = iPhoneOS,2.0

LDFLAGS = -arch armv6 
LDFLAGS += -isysroot $(SDK)
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
LDFLAGS += -framework ImageIO
LDFLAGS += -L"$(SDK)/usr/lib" 
LDFLAGS += -F"$(SDK)/System/Library/Frameworks" 
LDFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks" 

CFLAGS = -arch armv6
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
OBJS = $(patsubst %.mm,%.o,$(wildcard $(SRCDIR)/*.mm))
OBJS += $(patsubst %.c,%.o,$(wildcard $(SRCDIR)/*.c))
# OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/*.cpp))

OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/Source/Core/*.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/Source/Devices/MediaServer/*.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/Source/Apps/FrameStreamer/*.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/ThirdParty/Neptune/Source/Core/*.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/ThirdParty/Neptune/Source/System/Bsd/*.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/ThirdParty/Neptune/Source/System/Posix/*.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/ThirdParty/Neptune/Source/System/StdC/*.cpp))

CFLAGS += -I"$(SRCDIR)/Platinum/ThirdParty/Neptune/Source/Core"
CFLAGS += -I"$(SRCDIR)/Platinum/Source/Core"
CFLAGS += -I"$(SRCDIR)/Platinum/Source/Devices/MediaServer"
CFLAGS += -I"$(SRCDIR)/Platinum/Source/Apps/FrameStreamer" -isysroot $(SDK)
#CPPFLAGS = $(CFLAGS)

RESOURCES = $(wildcard $(RESDIR)/*)
ZIPNAME = $(PROJECTNAME).zip

all:	clean dist

$(PROJECTNAME):	$(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

%.o:	%.mm
	$(CC) -c -x objective-c++ $(CFLAGS) $< -o $@

%.o:	%.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

%.o:	%.cpp
	$(CC)  -x c++ -c $(CFLAGS) $(CPPFLAGS) $< -o $@

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
	@find src -type f -name *.o -print0 | xargs rm
	@find src -type f -name *.gch -print0 | xargs rm
	@rm -rf $(BUILDDIR)
	@rm -f $(ZIPNAME)
