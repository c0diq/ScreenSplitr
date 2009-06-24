# Makefile for Apple SDK with Open Tool Chain Headers for firmware 2.0

PROJECTNAME = ScreenSplitr
APPFOLDER=$(PROJECTNAME).app
INSTALLFOLDER=$(PROJECTNAME).app

IPHONE_IP=192.168.1.200
SDKVER=2.0

DEV = /Developer/Platforms/iPhoneOS.platform/Developer
SDK = $(DEV)/SDKs/iPhoneOS3.0.sdk
CC  = $(DEV)/usr/bin/gcc-4.0
LD  = $(DEV)/usr/bin/g++-4.0
VERSION = iPhoneOS,$(SDKVER)

LDFLAGS = -arch armv6 -mmacosx-version-min=10.5 -Wl,-dead_strip -miphoneos-version-min=2.2 -undefined suppress -force_flat_namespace
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
#LDFLAGS += -framework ImageIO
LDFLAGS += -L"$(SDK)/usr/lib" 
LDFLAGS += -F"$(SDK)/System/Library/Frameworks" 
LDFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks" 

CFLAGS = -arch armv6 -fmessage-length=0 -pipe -Wno-trigraphs -fpascal-strings -fasm-blocks -Os -mdynamic-no-pic -Wreturn-type -Wunused-variable -isysroot $(SDK) -fvisibility=hidden -fvisibility-inlines-hidden -gdwarf-2 -mthumb -miphoneos-version-min=2.2
CFLAGS += -I"$(SDK)/usr/include" 
CFLAGS += -I"$(DEV)/usr/lib/gcc/arm-apple-darwin9/4.0.1/include"
CFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks"
#CFLAGS += -DNPT_DEBUG -DNPT_CONFIG_ENABLE_LOGGING

BUILDDIR = ./build/3.0
SRCDIR = ./src
RESDIR = ./resources
OBJS = $(patsubst %.mm,%.o,$(wildcard $(SRCDIR)/*.mm))
OBJS += $(patsubst %.c,%.o,$(wildcard $(SRCDIR)/*.c))
# OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/*.cpp))

OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/Source/Core/*.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/Source/Devices/MediaServer/*.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/Source/Devices/FrameStreamer/*.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/ThirdParty/Neptune/Source/Core/*.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/ThirdParty/Neptune/Source/System/Bsd/*.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/ThirdParty/Neptune/Source/System/Posix/*.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/ThirdParty/Neptune/Source/System/StdC/NptStdcFile.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/ThirdParty/Neptune/Source/System/StdC/NptStdcEnvironment.cpp))
OBJS += $(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/Platinum/ThirdParty/Neptune/Source/System/StdC/NptStdcDebug.cpp))
RESOURCES = $(wildcard $(RESDIR)/*)

CFLAGS += -I"$(SRCDIR)/Platinum/ThirdParty/Neptune/Source/Core"
CFLAGS += -I"$(SRCDIR)/Platinum/Source/Core"
CFLAGS += -I"$(SRCDIR)/Platinum/Source/Devices/MediaServer"
CFLAGS += -I"$(SRCDIR)/Platinum/Source/Devices/FrameStreamer"
#CPPFLAGS = $(CFLAGS)


CPPFLAGS = $(CFLAGS)
#CPPFLAGS += -pedantic

all:	$(PROJECTNAME)

$(PROJECTNAME):	$(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

%.o:	%.m
	$(CC) -c $(CFLAGS) $< -o $@

%.o:	%.mm
	$(CC) -c -x objective-c++ $(CFLAGS) $< -o $@

%.o:	%.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

%.o:	%.cpp
	$(CC) -c -x c++ $(CFLAGS) $(CPPFLAGS) $< -o $@

dist:	$(PROJECTNAME)
	rm -rf $(BUILDDIR)
	mkdir -p $(BUILDDIR)/$(APPFOLDER)
ifneq ($(RESOURCES),)
	cp -r $(RESOURCES) $(BUILDDIR)/$(APPFOLDER)
	find $(BUILDDIR) -type f -name .DS_Store -print0 | xargs -0 rm
	find $(BUILDDIR) -name .svn -print0 | xargs -0 rm -rf
endif
	cp Info.plist $(BUILDDIR)/$(APPFOLDER)/Info.plist
	@echo "APPL????" > $(BUILDDIR)/$(APPFOLDER)/PkgInfo
ifneq ($(NIBS),)
	mv $(NIBS) $(BUILDDIR)/$(APPFOLDER)
endif
	export CODESIGN_ALLOCATE=$(DEV)/usr/bin/codesign_allocate; ./ldid_mac -S $(PROJECTNAME)
	mv $(PROJECTNAME) $(BUILDDIR)/$(APPFOLDER)

install: dist
	ping -t 3 -c 1 $(IPHONE_IP)
    	#ssh root@$(IPHONE_IP) 'killall ${PROJECTNAME} > /dev/null 2>&1'
	ssh root@$(IPHONE_IP) 'rm -fr /Applications/$(INSTALLFOLDER)'
	scp -r $(BUILDDIR)/$(APPFOLDER) root@$(IPHONE_IP):/Applications/$(INSTALLFOLDER)
	@echo "Application $(INSTALLFOLDER) installed, please respring iPhone"
	#ssh root@$(IPHONE_IP) 'ldid -S /Applications/$(INSTALLFOLDER)/ScreenSplitr;restart'
	ssh root@$(IPHONE_IP) 'restart'

uninstall:
	ping -t 3 -c 1 $(IPHONE_IP)
	ssh root@$(IPHONE_IP) 'rm -fr /Applications/$(INSTALLFOLDER); restart'
	@echo "Application $(INSTALLFOLDER) uninstalled, please respring iPhone"

install_respring:
	ping -t 3 -c 1 $(IPHONE_IP)
	scp respring root@$(IPHONE_IP):/usr/bin/respring

install_restart:
	ping -t 3 -c 1 $(IPHONE_IP)
	scp restart root@$(IPHONE_IP):/usr/bin/restart

clean:
	@find src -type f -name *.o | xargs rm
	@find src -type f -name *.gch | xargs rm
	@rm -rf $(BUILDDIR)
	@rm -f $(ZIPNAME)
